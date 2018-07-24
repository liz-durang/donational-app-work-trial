class CampaignContributionsController < ApplicationController
  def create
    ensure_current_donor!

    pipeline = Flow.new
    pipeline.chain { update_donor! }
    pipeline.chain { associate_donor_with_partner! }
    pipeline.chain { store_custom_donor_information! }
    pipeline.chain { subscribe_donor_to_managed_portfolio! }
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! }
    pipeline.chain { schedule_first_contribution_immediately! } unless future_start_date?

    new_unprocessed_contributions = Contributions::GetUnprocessedContributions.call(donor: current_donor)
    new_unprocessed_contributions.each do |c|
      pipeline.chain { Contributions::ProcessContribution.run(contribution: c) }
    end

    outcome = pipeline.run

    if outcome.success?
      redirect_to portfolio_path(show_modal: true)
    else
      redirect_to campaigns_path(campaign.slug), alert: outcome.errors.message_list.join('\n')
    end
  end

  private

  def update_donor!
    Donors::UpdateDonor.run(
      donor: current_donor,
      first_name: params[:campaign_contribution][:first_name],
      last_name: params[:campaign_contribution][:last_name],
      email: params[:campaign_contribution][:email]
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
      payment_token: payment_token
    )
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      amount_cents: amount_cents,
      frequency: params[:campaign_contribution][:frequency],
      start_at: params[:campaign_contribution][:start_at].presence,
      tips_cents: 0
    )
  end

  def schedule_first_contribution_immediately!
    Contributions::ScheduleContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      amount_cents: amount_cents,
      tips_cents: 0,
      scheduled_at: Time.zone.now
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

  def amount_cents
    params[:campaign_contribution][:amount_dollars].to_i * 100
  end

  def payment_token
    params[:campaign_contribution][:payment_token]
  end

  def future_start_date?
    return false if params[:campaign_contribution][:start_at].blank?

    Date.parse(params[:campaign_contribution][:start_at]) > Date.today
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

    log_in! new_donor
  end

  def campaign
    @campaign ||= Partners::GetCampaignBySlug.call(slug: params[:campaign_slug])
  end

  def partner
    @partner ||= campaign.partner
  end
end
