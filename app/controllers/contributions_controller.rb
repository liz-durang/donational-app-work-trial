class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    redirect_to edit_payment_methods_path and return unless active_payment_method?

    active_portfolio
    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)
  end

  def create
    redirect_to edit_payment_methods_path and return unless active_payment_method?

    amount_dollars = params[:portfolio][:amount_dollars].to_i

    Contributions::CreateContribution.run!(
      portfolio: active_portfolio,
      amount_cents: amount_dollars * 100
    )

    track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })

    redirect_to contributions_path
  end

  private

  def active_payment_method?
    PaymentMethods::GetActivePaymentMethod.call(donor: current_donor).present?
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
