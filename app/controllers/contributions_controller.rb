class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    redirect_to edit_payment_methods_path and return unless active_payment_method?

    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)
  end

  def create
    redirect_to edit_payment_methods_path and return unless active_payment_method?

    Contributions::CreateContribution.run!(
      portfolio: active_portfolio,
      amount_cents: params[:amount_dollars].to_i * 100
    )

    send_client_side_analytics_event('Goal: Donation', { revenue: params[:amount_dollars].to_i })

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
