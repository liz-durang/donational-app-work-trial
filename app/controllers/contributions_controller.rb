class ContributionsController < ApplicationController
  include Secured

  def create
    save_donor_credit_card!

    contribution = Contribution.create!(
      portfolio: active_portfolio,
      amount_cents: params[:amount_cents].to_i,
      scheduled_at: Time.zone.now
    )

    Contributions::ProcessContribution.run(contribution: contribution)

    render json: contribution
  end

  private

  def save_donor_credit_card!
    Donors::UpdatePaymentMethod.run!(
      donor: current_donor,
      payment_token: params[:payment_token]
    )
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
