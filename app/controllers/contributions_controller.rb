class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    active_portfolio
    payment_method
    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)
  end

  def create
    redirect_to contributions_path and return unless active_payment_method?

    amount_dollars = params[:portfolio][:amount_dollars].to_i

    Contributions::CreateContribution.run!(
      portfolio: active_portfolio,
      amount_cents: amount_dollars * 100
    )

    active_portfolio.update(
      contribution_frequency: params[:portfolio][:contribution_frequency],
      contribution_amount_cents: amount_dollars * 100
    )

    track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })

    redirect_to contributions_path
  end

  private

  def active_payment_method?
    payment_method.present?
  end

  def payment_method
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
