class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    redirect_to new_contribution_path and return unless active_payment_method?

    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)
  end

  def new
    active_portfolio
    payment_method
  end

  def create
    save_donor_credit_card portfolio_params[:payment_token]

    redirect_to new_contribution_path and return unless active_payment_method?

    amount_dollars = portfolio_params[:contribution_amount_dollars].to_i

    Contributions::CreateContribution.run!(
      portfolio: active_portfolio,
      amount_cents: amount_dollars * 100
    )

    active_portfolio.update(
      contribution_frequency: portfolio_params[:contribution_frequency],
      contribution_amount_cents: amount_dollars * 100
    )

    track_analytics_event_via_browser(
      'Goal: Donation',
      { revenue: amount_dollars }
    )

    redirect_to contributions_path
  end

  private

  def save_donor_credit_card(token)
    return unless token.present?

    Donors::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: token
    )
  end

  def active_payment_method?
    payment_method.present?
  end
  helper_method :active_payment_method?

  def payment_method
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def portfolio_params
    params[:portfolio]
  end
end
