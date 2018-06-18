class CampaignContributionsController < ApplicationController
  def create
    ensure_current_donor!

    pipeline = Flow.new
    pipeline.chain { update_donor! }
    pipeline.chain { associate_donor_with_partner! }
    #TODO pipeline.chain { store_custom_donor_information! }
    pipeline.chain { create_portfolio_from_template! }
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! }
    pipeline.chain { schedule_first_contribution_immediately! }

    new_unprocessed_contributions = Contributions::GetUnprocessedContributions.call(donor: current_donor)
    new_unprocessed_contributions.each do |c|
      pipeline.chain { Contributions::ProcessContribution.run(contribution: c) }
    end

    outcome = pipeline.run

    if outcome.success?
      redirect_to contributions_path
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

  def create_portfolio_from_template!
    template = PortfolioTemplate.find(params[:campaign_contribution][:portfolio_template_id])
    Portfolios::CreateOrReplacePortfolio.run(donor: current_donor)
    Portfolios::AddOrganizationsAndRebalancePortfolio.run(
      portfolio: active_portfolio,
      organization_eins: template.organization_eins
    )
  end

  def store_custom_donor_information!
    # Partners::UpdateDonorCustomInformation.run(donor: current_donor, partner: partner, campaign: campaign)
  end

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: payment_token,
      name_on_card: name_on_card,
      last4: last4
    )
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      frequency: frequency,
      amount_cents: amount_cents,
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

  def amount_cents
    params[:campaign_contribution][:amount_dollars].to_i * 100
  end

  def payment_token
    params[:campaign_contribution][:payment_token]
  end

  def frequency
    params[:campaign_contribution][:frequency]
  end

  def name_on_card
    params[:campaign_contribution][:name_on_card]
  end

  def last4
    params[:campaign_contribution][:last4]
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
