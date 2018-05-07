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
    save_card_command = save_donor_credit_card(portfolio_params[:payment_token])

    unless active_payment_method?
      redirect_to new_contribution_path, alert: save_card_command.errors.message_list.join(' ')
      return
    end

    Contributions::CreateContribution.run!(
      donor: current_donor,
      portfolio: active_portfolio,
      amount_cents: contribution_amount_cents,
      platform_fee_cents: platform_fee_cents
    )

    active_portfolio.update(
      contribution_frequency: portfolio_params[:contribution_frequency],
      contribution_amount_cents: contribution_amount_cents,
      contribution_platform_fee_cents: platform_fee_cents
    )

    track_analytics_event_via_browser('Goal: Donation', { revenue: contribution_amount_dollars })

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

  def contribution_amount_cents
    contribution_amount_dollars * 100
  end

  def platform_fee_cents
    portfolio_params[:contribution_platform_fee_cents].to_i
  end

  def contribution_amount_dollars
    portfolio_params[:contribution_amount_dollars].to_i
  end
end
