class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    @view_model = OpenStruct.new(
      contributions: Contributions::GetContributions.call(donor: current_donor),
      first_contribution: Contributions::GetFirstContribution.call(donor: current_donor),
      recurring_contribution: active_recurring_contribution
    )
  end

  def new
    if active_recurring_contribution.present?
      redirect_to edit_accounts_path
    else
      @view_model = OpenStruct.new(
        target_amount_cents: target_amount_cents,
        recurring_contribution: new_recurring_contribution,
        active_payment_method?: payment_method.present?,
        partner_affiliation: partner_affiliation,
        partner_affiliation?: partner_affiliation.present?,
        selectable_portfolios: selectable_portfolios
      )
    end
  end

  def create
    pipeline = Flow.new
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! }

    outcome = pipeline.run

    if outcome.success?
      track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })
      flash[:success] = "We've updated your donation plan"
      redirect_to edit_accounts_path
    else
      redirect_to new_contribution_path, alert: outcome.errors.message_list.join('\n')
    end
  end

  def destroy
    Contributions::DeactivateRecurringContribution.run(recurring_contribution: active_recurring_contribution)

    flash[:success] = "We've cancelled your donation plan"
    redirect_to edit_accounts_path
  end

  private

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: payment_token
    )
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: Portfolio.find(portfolio_id),
      partner: partner,
      frequency: frequency,
      amount_cents: amount_cents,
      tips_cents: tips_cents,
      start_at: start_at,
      partner_contribution_percentage: 0
    )
  end

  def payment_method
    @payment_method = Payments::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_recurring_contribution
    @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: current_donor)
  end

  def partner_affiliation
    @partner_affiliation ||= Partners::GetPartnerAffiliationByDonor.call(donor: current_donor)
  end

  def partner
    @partner ||= Partners::GetPartnerForDonor.call(donor: current_donor)
  end

  def managed_portfolio?
    Portfolios::GetPortfolioManager.call(portfolio: active_portfolio).present?
  end

  def selectable_portfolios
    portfolios = []
    portfolios << [active_portfolio.id, 'My personalized portfolio'] unless managed_portfolio?    
    portfolios += Partners::GetManagedPortfoliosForPartner.call(partner: partner).pluck(:portfolio_id, :name) if partner
    portfolios
  end

  def new_recurring_contribution
    RecurringContribution.new(
      donor: current_donor,
      amount_cents: target_amount_cents,
      portfolio: active_portfolio,
      frequency: current_donor.contribution_frequency
    )
  end

  def target_amount_cents
    Contributions::GetTargetContributionAmountCents.call(
      donor: current_donor,
      frequency: active_recurring_contribution.try(:frequency) || current_donor.contribution_frequency
    )
  end

  def amount_cents
    amount_dollars * 100
  end

  def tips_cents
    params[:recurring_contribution][:tips_cents].to_i
  end

  def amount_dollars
    params[:recurring_contribution][:amount_dollars].to_i
  end

  def payment_token
    params[:recurring_contribution][:payment_token]
  end

  def frequency
    params[:recurring_contribution][:frequency]
  end

  def portfolio_id
    params[:recurring_contribution][:portfolio_id]
  end

  def start_at
    start_at_param = params.dig(:recurring_contribution, :start_at)
    Time.zone.parse(start_at_param) if start_at_param
  end
end
