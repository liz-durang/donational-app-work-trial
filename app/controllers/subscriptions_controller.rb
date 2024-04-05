class SubscriptionsController < ApplicationController
  helper_method :find_question, :partner, :show_chapter_question?
  layout 'oftw_checkout_flow'
  before_action :set_up_view_model, only: %i[new]

  DEFAULT_MINIMUM_CONTRIBUTION = 20
  DEFAULT_CONTRIBUTION_AMOUNT_HELP_TEXT = 'The average person living in a high-income country like the US, Canada, UK, or Australia usually gives a small percentage of their income each year. The average American gives 2.6%.'.freeze
  COMMS_INFO_TEXT = 'One for the World would occasionally like to send you information about our charities, your impact and other initiatives. If you are happy to receive this information, please indicate here.'.freeze
  COMMS_SMS_INFO = 'By selecting this box, you agree to receive donor engagement texts from One For The World. Message frequency varies. Message and data rates may apply. Reply STOP to unsubscribe at any time.'.freeze
  COUNTRY_LEVEL_CAMPAIGN_SLUGS = %w[oftw oftw-uk oftw-aus oftw-canada].freeze

  def new
    if params[:campaign_slug].present? && (campaign.nil? || !campaign.partner.active? || !campaign.partner.uses_one_for_the_world_checkout?)
      not_found and return
    end

    not_found and return if partner.present? && (!partner.active? || !partner.uses_one_for_the_world_checkout?)

    @after_return_from_successful_stripe_checkout = params[:stripe_session_id].present?

    if params.key?('pledge_form') && @after_return_from_successful_stripe_checkout
      # In this logical branch, we are returning to step 4 after a form submission that failed validation.
      @view_model.pledge_form = PledgeForm.new(pledge_form_params)
    elsif @after_return_from_successful_stripe_checkout
      # Retrieve partially filled form from Stripe Checkout session metadata
      @view_model.pledge_form = PledgeForm.new(payment_processor_checkout_session.metadata.to_h)
      # Pre-populate form with information that the user has already typed in for Stripe
      @view_model.pledge_form.first_name = first_name_from_payment_processor_customer
      @view_model.pledge_form.last_name = last_name_from_payment_processor_customer
      @view_model.pledge_form.email = email_from_payment_processor_customer
      @view_model.pledge_form.payment_processor_customer_id = payment_processor_checkout_session.customer.id
      @view_model.pledge_form.payment_processor_payment_method_type = payment_processor_checkout_session
                                                                      .setup_intent.payment_method.type
      @view_model.pledge_form.stripe_session_id = params[:stripe_session_id]

      unless @view_model.pledge_form.steps_before_payment_processor_are_valid?
        # TODO: Have a error page for users on production with better UX than just a json object.
        handle_error(@view_model.pledge_form.errors.full_messages.to_s) and return
      end
    end
  end

  def create_stripe_checkout_session
    pledge_form = PledgeForm.new(pledge_form_params)

    unless pledge_form.steps_before_payment_processor_are_valid?
      handle_error(pledge_form.errors.full_messages.to_s) and return
    end

    session = Stripe::Checkout::Session.create({ mode: 'setup',
                                                 customer_creation: 'always',
                                                 success_url: stripe_success_url,
                                                 cancel_url: stripe_cancel_url,
                                                 metadata: pledge_form_params.to_h,
                                                 currency: partner.currency.downcase,
                                                 payment_method_options:, # Configuration per payment method
                                                 payment_method_types: [pledge_form_params[:payment_method_id]] },
                                               { stripe_account: partner.payment_processor_account_id })

    render json: { sessionUrlForStripeHostedPage: session.url }
  rescue Stripe::InvalidRequestError => e
    handle_error(e) and return
  end

  def create
    pipeline = Flow.new

    pipeline.chain { Subscriptions::ValidatePledgeForm.run(pledge_form: PledgeForm.new(pledge_form_params)) }
    if current_donor.blank? || Partners::GetPartnerForDonor.call(donor: current_donor).id != partner.id
      # If the donor has selected a portfolio from a different partner than that which they are affiliated to,
      # effectively choosing a new partner affiliation, we should allow a new donor record to be created,
      # because we need to be able to rely on this affiliation to pay the correct partner.
      pipeline.chain { create_donor! }
    end
    pipeline.chain { update_donor! }
    pipeline.chain { associate_donor_with_partner! }
    pipeline.chain { store_custom_donor_information! }
    pipeline.chain { subscribe_donor_to_managed_portfolio! }
    pipeline.chain { update_donor_payment_method! }
    pipeline.chain { update_subscription! }

    outcome = pipeline.run

    if outcome.success?
      redirect_to partner.after_donation_thank_you_page_url, allow_other_host: true
    else
      handle_error(outcome.errors.message_list.join('; '))
      redirect_to stripe_success_url(query_params: { pledge_form: pledge_form_params }),
                  alert: outcome.errors.message_list.join("\n")
    end
  end

  private

  def set_up_view_model
    @view_model = OpenStruct.new(
      boxes_checked_by_default: %w[givewell_comms OFTW_discretion nonprofit_comms],
      campaign:,
      comms_info_text: COMMS_INFO_TEXT,
      comms_sms_info: COMMS_SMS_INFO,
      currency_code: partner&.currency&.upcase,
      minimum_contribution_amount:,
      contribution_amount_help_text: campaign&.contribution_amount_help_text || DEFAULT_CONTRIBUTION_AMOUNT_HELP_TEXT,
      chapters:,
      currencies: partner_currency_options,
      donor_questions:,
      portfolios_by_partner: managed_portfolios_by_partner,
      months: I18n.t('date.month_names').compact,
      next_fifteenth:,
      partners: oftw_partners,
      titles: Constants::GetTitles.call,
      years:,
      payment_method_options: Constants::GetLocalizedPaymentMethods.call,
      pledge_form: PledgeForm.new,
      portfolio_id_to_name_mapping:,
      currency_to_payment_processor_account_id_mapping:
    )
  end

  def interval_description
    month = pledge_form_params[:start_at_month]
    year = pledge_form_params[:start_at_year]

    if month.present? && year.present?
      "on the 15th of every month, starting #{month} #{year}"
    else
      'on the 15th of every month'
    end
  end

  def payment_method_options
    if pledge_form_params[:payment_method_id] == 'acss_debit'
      { acss_debit: { # copied from app/queries/payments/generate_acss_client_secret_for_donor
        currency: 'cad',
        mandate_options: {
          payment_schedule: 'interval',
          interval_description:,
          transaction_type: 'personal'
        }
      } }
    else
      {}
    end
  end

  def partner
    # NB the Partner can be different from that referred to by campaign.partner_id, since e.g. international students may
    # select a different currency than the campaign.partner's currency on step 1, and the choice of currency should
    # determine the partner.
    @partner ||= Partners::GetPartnerById.call(id: params[:partner_id] || params[:pledge_form]&.dig(:partner_id))
  end

  def pledge_form_params
    params.require(:pledge_form).permit(PledgeForm::ATTRIBUTES)
  end

  def managed_portfolios_by_partner
    @managed_portfolios_by_partner ||= ManagedPortfolio
                                       .includes(%i[portfolio partner])
                                       .with_attached_image
                                       .where(partners: oftw_partners, hidden_at: nil)
                                       .order(display_order: :asc)
                                       .group_by { |mp| mp.partner.currency }
  end

  def partner_currency_options
    currency_flags = {
      USD: '🇺🇸',
      GBP: '🇬🇧',
      CAD: '🇨🇦',
      AUD: '🇦🇺',
      EUR: '🇪🇺'
    }.with_indifferent_access

    oftw_partners.map do |partner|
      option_text = [currency_flags[partner.currency.upcase], partner.currency.upcase].join(' ')
      [option_text, partner.id]
    end
  end

  def oftw_partners
    @oftw_partners ||= Partners::GetOftwPartners.call
  end

  def portfolio_id_to_name_mapping
    managed_portfolios_by_partner.values.flatten.each_with_object({}) do |partner, hash|
      hash[partner.id] = partner.name
    end
  end

  def currency_to_payment_processor_account_id_mapping
    oftw_partners.each_with_object({}) { |partner, hash| hash[partner.currency] = partner.payment_processor_account_id }
  end

  def stripe_account
    partner.payment_processor_account_id
  end

  def chapters
    Partners::GetChapterOptionsByPartnerOrCampaign.call(campaign_id: campaign&.id, partner_id: partner&.id)
  end

  def campaign
    @campaign ||= if params[:campaign_slug].present?
                    Partners::GetCampaignBySlug.call(slug: params[:campaign_slug].parameterize)
                  elsif params[:pledge_form]&.dig(:campaign_id).present?
                    Partners::GetCampaignById.call(id: params[:pledge_form][:campaign_id])
                  end
  end

  def years
    [Time.zone.today.year, Time.zone.today.year + 1, Time.zone.today.year + 2, Time.zone.today.year + 3,
     Time.zone.today.year + 4, Time.zone.today.year + 5].freeze
  end

  def stripe_success_url(query_params: {})
    url_environment_prefix = ('review' if Rails.env.staging? || Rails.env.test?)
    url_campaign_prefix = ('campaign' if campaign.present?)
    url_method_name = [url_environment_prefix, url_campaign_prefix, 'take_the_pledge_url'].compact.join('_')

    # When creating a checkout session, Stripe will find-and-replace the string '{CHECKOUT_SESSION_ID}'.
    # If a Stripe checkout session has already been created, use the existing session.
    checkout_session_id = pledge_form_params[:stripe_session_id] || '{CHECKOUT_SESSION_ID}'

    url_params = { campaign_slug: campaign&.slug, stripe_session_id: checkout_session_id,
                   partner_id: partner.id }.merge(query_params).select { |_key, value| value.present? }
    public_send(url_method_name, url_params)
      .gsub('%7B', '{').gsub('%7D', '}') # Stripe only recognises '{CHECKOUT_SESSION_ID}' in its un-encoded form.
  end

  def stripe_cancel_url
    url_environment_prefix = ('review' if Rails.env.staging? || Rails.env.test?)
    url_campaign_prefix = ('campaign' if campaign.present?)
    url_method_name = [url_environment_prefix, url_campaign_prefix, 'take_the_pledge_url'].compact.join('_')
    url_params = { campaign_slug: params[:campaign_slug] }.select { |_key, value| value.present? }
    public_send(url_method_name, url_params)
  end

  def show_chapter_question?
    # In general, we save users time by skipping the chapter question if the answer can be inferred from the campaign.
    # For campaigns attached to entire countries, we should retain the chapter question.

    find_question('chapter') && @view_model.campaign.present? && COUNTRY_LEVEL_CAMPAIGN_SLUGS.exclude?(@view_model.campaign.slug)
  end

  def find_question(name)
    @view_model.donor_questions.find { |q| q.name == name }
  end

  def donor_questions
    @donor_questions ||= partner&.donor_questions || []
  end

  def minimum_contribution_amount
    [campaign&.minimum_contribution_amount.to_i, DEFAULT_MINIMUM_CONTRIBUTION].max
  end

  def create_donor!
    outcome = Donors::CreateDonorAffiliatedWithPartner.run(
      first_name: pledge_form_params[:first_name],
      last_name: pledge_form_params[:last_name],
      email: pledge_form_params[:email],
      partner:,
      campaign:
    )

    log_out! if current_donor
    log_in!(outcome.result) if outcome.success?

    outcome
  end

  def update_donor!
    # Apply 'compact' to these attributes to avoid updating a donor's uk_gift_aid_accepted to the
    # default value unnecessarily.
    updateable_attributes = { contribution_frequency: 'monthly',
                              first_name: pledge_form_params[:first_name],
                              last_name: pledge_form_params[:last_name],
                              email: pledge_form_params[:email],
                              partner:,
                              donor: current_donor,
                              title: pledge_form_params[:title],
                              house_name_or_number: pledge_form_params[:house_name_or_number],
                              postcode: pledge_form_params[:postcode],
                              uk_gift_aid_accepted: pledge_form_params[:uk_gift_aid_accepted].presence,
                              annual_income_cents: 100 * pledge_form_params[:estimated_future_annual_income].to_i }.compact
    Donors::UpdateDonor.run(updateable_attributes)
  end

  def associate_donor_with_partner!
    Partners::AffiliateDonorWithPartner.run(donor: current_donor, partner:, campaign:)
  end

  def store_custom_donor_information!
    Partners::UpdateCustomDonorInformation.run(
      donor: current_donor,
      partner:,
      responses: custom_question_responses
    )
  end

  def subscribe_donor_to_managed_portfolio!
    Portfolios::SelectPortfolio.run(
      donor: current_donor,
      portfolio: managed_portfolio.portfolio
    )
  end

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      processor_payment_method: payment_processor_checkout_session.setup_intent.payment_method,
      customer_id: pledge_form_params[:payment_processor_customer_id],
      is_checkout_session: true
    )
  end

  def update_subscription!
    Contributions::CreateOrReplaceSubscription.run(
      donor: current_donor,
      portfolio: Portfolios::GetActivePortfolio.call(donor: current_donor),
      partner:,
      amount_cents: pledge_form_params[:amount_cents].to_i,
      frequency: 'monthly',
      start_at:,
      tips_cents: 0,
      partner_contribution_percentage: 0,
      trial_amount_cents:
    )
  end

  def custom_question_responses
    permitted_question_keys = partner.donor_questions.map(&:name)
    responses = params
                .require(:pledge_form)
                .permit(permitted_question_keys)
                .to_h
                .transform_keys do |k|
      k.gsub('birthday(2i)', 'birthday_month')
       .gsub('birthday(3i)', 'birthday_day')
    end.except('birthday(1i)')

    responses['chapter'] = 'N/A' if responses['chapter'].blank?

    responses
  end

  def managed_portfolio
    @managed_portfolio ||= Partners::GetManagedPortfolioById.call(id: pledge_form_params[:managed_portfolio_id])
  end

  def start_at
    start_at_year = pledge_form_params[:start_at_year]
    start_at_month = pledge_form_params[:start_at_month]
    start_at_day = 15

    return Time.zone.now if start_at_month.blank? || start_at_year.blank?

    start_at_month_to_i = (I18n.t('date.month_names').compact.index(start_at_month) + 1)
    Time.zone.local(start_at_year.to_i, start_at_month_to_i, start_at_day,
                    12, 0)
  end

  def trial_amount_cents
    fifteenth = Time.zone.local(Date.today.year, Date.today.month, 15, 12, 0)
    months = ((start_at.year * 12) + start_at.month) - ((fifteenth.year * 12) + fifteenth.month)

    months > 1 ? pledge_form_params[:trial_amount_dollars].to_i * 100 : 0
  end

  def next_fifteenth
    if Time.zone.today.day > 15
      Time.zone.local(Time.zone.today.year, Time.zone.today.month + 1,
                      15)
    elsif Time.zone.today.day < 15
      Time.zone.local(Time.zone.today.year, Time.zone.today.month, 15)
    elsif Time.zone.today.day == 15
      Time.zone.today
    end
  end

  def first_name_from_payment_processor_customer
    payment_processor_customer.name.split(' ').first
  end

  def last_name_from_payment_processor_customer
    payment_processor_customer.name.split(' ').last
  end

  def email_from_payment_processor_customer
    payment_processor_checkout_session.customer_details.email || payment_processor_checkout_session.customer_email || payment_processor_customer.email
  end

  def payment_processor_customer
    @payment_processor_customer ||= payment_processor_checkout_session.customer
  end

  def payment_processor_checkout_session
    # We use 'expand' to reduce number of requests required https://stripe.com/docs/expand?locale=en-GB
    @payment_processor_checkout_session ||= Stripe::Checkout::Session.retrieve(
      { expand: ['customer', 'setup_intent.payment_method'],
        id: (params[:stripe_session_id] || pledge_form_params[:stripe_session_id]) },
      { stripe_account: }
    )
  end

  def handle_error(error)
    if Rails.env.staging? || Rails.env.development?
      @method = action_name
      @params = params.permit!
      @errors = error
      render 'error' unless action_name == 'create'
    else
      Sentry.capture_exception(RuntimeError.new(error), extra: { donor_id: current_donor&.id })
      render json: { status: 500 } unless action_name == 'create'
    end
  end
end
