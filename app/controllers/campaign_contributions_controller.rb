class CampaignContributionsController < ApplicationController
  skip_forgery_protection only: [:create]

  def create
    ensure_current_donor!

    pipeline = Flow.new
    pipeline.chain { update_donor! }
    pipeline.chain { associate_donor_with_partner! }
    pipeline.chain { store_custom_donor_information! }
    pipeline.chain { subscribe_donor_to_managed_portfolio! }
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! }

    outcome = pipeline.run

    if outcome.success?
      redirect_to portfolio_path(show_modal: true)
    else
      redirect_to campaigns_path(campaign.slug), alert: outcome.errors.message_list.join("\n")
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
      portfolio: Partners::GetManagedPortfolioById.call(id: managed_portfolio_id).portfolio
    )
  end

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: params[:campaign_contribution][:payment_token]
    )
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      partner: partner,
      amount_cents: params[:campaign_contribution][:amount_dollars].to_i * 100,
      frequency: params[:campaign_contribution][:frequency],
      start_at: start_at,
      tips_cents: 0,
      partner_contribution_percentage: params[:campaign_contribution][:partner_contribution_percentage].to_i
    )
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_recurring_contribution
    @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: current_donor)
  end

  def managed_portfolio_id
    params[:campaign_contribution][:managed_portfolio_id]
  end

  def payment_token
    params[:campaign_contribution][:payment_token]
  end

  def start_at
    start_at_param = params.dig(:campaign_contribution, :start_at)
    Time.zone.parse(start_at_param) if start_at_param
  end

  def custom_question_responses
    permitted_question_keys = partner.donor_questions.map(&:name)
    params
      .require(:campaign_contribution)
      .permit(donor_questions: permitted_question_keys)[:donor_questions]
      .to_h
  end

  def ensure_current_donor!
    return if current_donor
    new_donor = Donors::CreateAnonymousDonor.run!

    log_in!(new_donor)
  end

  def campaign
    @campaign ||= Partners::GetCampaignBySlug.call(slug: params[:campaign_slug].parameterize)
  end

  def partner
    @partner ||= campaign.partner
  end

  def uk_partner?
    partner.currency == 'GBP'
  end
end
