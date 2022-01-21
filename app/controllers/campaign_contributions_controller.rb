class CampaignContributionsController < ApplicationController
  skip_forgery_protection only: [:create]

  def create
    pipeline = Flow.new
    pipeline.chain { create_donor! } unless current_donor
    pipeline.chain { update_donor! }
    pipeline.chain { associate_donor_with_partner! }
    pipeline.chain { store_custom_donor_information! }
    pipeline.chain { subscribe_donor_to_managed_portfolio! }
    pipeline.chain { update_donor_payment_method! } if payment_method_id.present? || payment_token.present?
    pipeline.chain { update_subscription! }

    outcome = pipeline.run

    if outcome.success?
      if partner.after_donation_thank_you_page_url.nil? || partner.after_donation_thank_you_page_url.empty?
        redirect_to portfolio_path(show_modal: true)
      else
        render 'partners/_redirect', locals: {redirect_url: partner.after_donation_thank_you_page_url}
      end
    else
      redirect_to campaigns_path(campaign.slug), alert: outcome.errors.message_list.join("\n")
    end

    respond_to do |format|
      format.js
      format.html do
        allow_iframe_embedding_on_partner_website!
      end
    end
  end

  private

  def update_donor!
    Donors::UpdateDonor.run(
      donor: current_donor,
      first_name: params[:campaign_contribution][:first_name],
      last_name: params[:campaign_contribution][:last_name],
      email: params[:campaign_contribution][:email],
      title: params[:campaign_contribution][:title],
      house_name_or_number: params[:campaign_contribution][:house_name_or_number],
      postcode: params[:campaign_contribution][:postcode],
      uk_gift_aid_accepted: params[:campaign_contribution][:uk_gift_aid_accepted]
    )
  end

  def associate_donor_with_partner!
    Partners::AffiliateDonorWithPartner.run(donor: current_donor, partner: partner, campaign: campaign)
  end

  def store_custom_donor_information!
    Partners::UpdateCustomDonorInformation.run(
      donor: current_donor,
      partner: partner,
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
      payment_token: payment_token,
      payment_method_id: payment_method_id,
      customer_id: customer_id
    )
  end

  def update_subscription!
    Contributions::CreateOrReplaceSubscription.run(
      donor: current_donor,
      portfolio: active_portfolio,
      partner: partner,
      amount_cents: params[:campaign_contribution][:amount_dollars].to_i * 100,
      frequency: params[:campaign_contribution][:frequency],
      start_at: start_at,
      tips_cents: 0,
      partner_contribution_percentage: params[:campaign_contribution][:partner_contribution_percentage].to_i,
      trial_amount_cents: trial_amount_cents
    )
  end

  def allow_iframe_embedding_on_partner_website!
    response.headers['X-Content-Security-Policy'] = "frame-ancestors #{partner.website_url}"
    response.headers['Content-Security-Policy'] = "frame-ancestors #{partner.website_url}"
    response.headers.delete 'X-Frame-Options'
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def managed_portfolio_id
    params[:campaign_contribution][:managed_portfolio_id]
  end

  def payment_method_id
    params[:campaign_contribution][:payment_method_id]
  end

  def payment_token
    params[:campaign_contribution][:payment_token]
  end

  def customer_id
    params[:customer_id]
  end

  def start_at
    start_at_month = params.dig(:campaign_contribution, :start_at_month)
    start_at_year = params.dig(:campaign_contribution, :start_at_year)

    return nil if start_at_month.blank? || start_at_year.blank?

    Time.zone.local(start_at_year, start_at_month, 15, 12, 0)
  end

  def trial_amount_cents
    fifteenth = Time.zone.local(Date.today.year, Date.today.month, 15, 12, 0)
    months = (start_at.year * 12 + start_at.month) - (fifteenth.year * 12 + fifteenth.month)

    months > 1 ? params[:campaign_contribution][:trial_amount_dollars].to_i * 100 : 0
  end

  def custom_question_responses
    permitted_question_keys = partner.donor_questions.map(&:name)
    params
      .require(:campaign_contribution)
      .permit(donor_questions: permitted_question_keys)[:donor_questions]
      .to_h
  end

  def create_donor!
    outcome = Donors::CreateDonorAffiliatedWithPartner.run(
      first_name: params[:campaign_contribution][:first_name],
      last_name: params[:campaign_contribution][:last_name],
      email: params[:campaign_contribution][:email],
      partner: partner,
      campaign: campaign
    )

    log_in!(outcome.result) if outcome.success?

    outcome
  end

  def campaign
    @campaign ||= Partners::GetCampaignBySlug.call(slug: params[:campaign_slug].parameterize)
  end

  def partner
    @partner ||= campaign.partner
  end

  def managed_portfolio
    @managed_portfolio ||= Partners::GetManagedPortfolioById.call(id: managed_portfolio_id) || Partners::GetManagedPortfoliosForPartner.call(partner: partner).first
  end
end
