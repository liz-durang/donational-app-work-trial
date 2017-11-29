class ContributionsController < ApplicationController
  include Secured

  def index
    redirect_to edit_payment_methods_path unless active_payment_method?

    @contributions = Contribution
      .where(portfolio: Portfolio.where(donor: current_donor))
      .where.not(processed_at: nil)
      .preload(:donations)
      .order(created_at: :desc)

  end

  def create
    contribution = Contribution.create!(
      portfolio: active_portfolio,
      amount_cents: params[:amount_dollars].to_i * 100,
      scheduled_at: Time.zone.now
    )

    Contributions::ProcessContribution.run(contribution: contribution)

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
