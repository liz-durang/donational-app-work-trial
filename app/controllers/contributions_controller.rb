class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    @view_model = OpenStruct.new(
      contributions: Contributions::GetContributions.call(donor: current_donor),
      first_contribution: Contributions::GetFirstContribution.call(donor: current_donor),
      subscription: active_subscription,
      currency: current_currency
    )
  end

  def new
    @view_model = OpenStruct.new(
      target_amount_cents: target_amount_cents,
      subscription: new_subscription,
      active_payment_method?: payment_method.present?,
      payment_method: payment_method || current_donor.payment_methods.new,
      partner_affiliation: partner_affiliation,
      partner_affiliation?: partner_affiliation.present?,
      selectable_portfolios: selectable_portfolios,
      currency_code: current_currency.iso_code,
      amount_cents: new_subscription.amount_cents,
      tips_options: tips_options,
      show_plaid?: partner.supports_plaid?
    )
  end

  def create
    outcome = Contributions::CreateOrReplaceSubscription.run(
      donor: current_donor,
      portfolio: Portfolio.find(portfolio_id),
      partner: partner,
      frequency: frequency,
      amount_cents: amount_cents,
      tips_cents: tips_cents,
      start_at: start_at,
      partner_contribution_percentage: 0
    )

    if outcome.success?
      track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })
      flash[:success] = "We've updated your donation plan"
      redirect_to edit_accounts_path
    else
      redirect_to new_contribution_path, alert: outcome.errors.message_list.join('\n')
    end
  end

  def destroy
    if params[:trial]
      Contributions::DeactivateTrial.run(subscription: active_trial)
      flash[:success] = "We've cancelled your donation trial"
    else
      Contributions::DeactivateSubscription.run(subscription: active_subscription)
      flash[:success] = "We've cancelled your donation plan"
    end

    redirect_to edit_accounts_path
  end

  private

  def tips_options
    [0, 200, 500, 1000].map do |amount|
      [
        amount,
        Money.new(amount, current_currency).format(no_cents_if_whole: true, display_free: 'No tip')
      ]
    end
  end

  def payment_method
    @payment_method = Payments::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_trial
    @active_trial ||= Contributions::GetActiveTrial.call(donor: current_donor)
  end

  def active_subscription
    @active_subscription ||= Contributions::GetActiveSubscription.call(donor: current_donor)
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
    portfolios << [active_portfolio.id, 'My personalized portfolio'] if active_portfolio && !managed_portfolio?
    portfolios += Partners::GetManagedPortfoliosForPartner.call(partner: partner).pluck(:portfolio_id, :name) if partner
    portfolios
  end

  def new_subscription
    Subscription.new(
      donor: current_donor,
      amount_cents: target_amount_cents,
      portfolio: active_portfolio,
      frequency: current_donor.contribution_frequency
    )
  end

  def target_amount_cents
    Contributions::GetTargetContributionAmountCents.call(
      donor: current_donor,
      frequency: active_subscription.try(:frequency) || current_donor.contribution_frequency
    )
  end

  def amount_cents
    amount_dollars * 100
  end

  def tips_cents
    params[:subscription][:tips_cents].to_i
  end

  def amount_dollars
    params[:subscription][:amount_dollars].to_i
  end

  def trial_amount_cents
    trial_amount_dollars * 100
  end

  def trial_amount_dollars
    params[:subscription][:trial_amount_dollars].to_i
  end

  def payment_token
    params[:subscription][:payment_token]
  end

  def frequency
    params[:subscription][:frequency]
  end

  def portfolio_id
    params[:subscription][:portfolio_id]
  end

  def start_at
    start_at_param = params.dig(:subscription, :start_at)
    Time.zone.parse(start_at_param) if start_at_param
  end
end
