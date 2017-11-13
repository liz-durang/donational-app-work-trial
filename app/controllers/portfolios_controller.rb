class PortfoliosController < ApplicationController
  include Secured

  def new
    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def create
    Portfolios::CreateOrReplacePortfolio.run!(
      donor: current_donor,
      donation_rate: current_donor.donation_rate,
      annual_income_cents: current_donor.annual_income_cents
    )

    Allocations::UpdateAllocations.run!(
      portfolio: active_portfolio,
      allocations: params[:allocations].values
    )

    redirect_to portfolio_path
  end

  def show
    @allocations = Allocations::GetActiveAllocations.call(portfolio: active_portfolio)
  end

  private

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
