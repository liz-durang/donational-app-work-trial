class PortfoliosController < ApplicationController
  include Secured

  def new
    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def create
    new_portfolio_command = Portfolios::CreateOrReplacePortfolio.run(
      donor: current_donor,
      donation_rate: current_donor.donation_rate,
      annual_income_cents: current_donor.annual_income_cents
    )

    if new_portfolio_command.success?
      update_allocations_command = Allocations::UpdateAllocations.run(
        portfolio: active_portfolio,
        allocations: params[:allocations].values
      )
    end

    redirect_to portfolio_path
  end

  def update
    command = Allocations::UpdateAllocations.run(
      portfolio: active_portfolio,
      allocations: params[:allocations].values
    )

    if command.success?
      flash[:success] = 'Allocations saved!'
      redirect_to portfolio_path
    else
      @allocations = params[:allocations].values.map { |a| Allocation.new(a) }
      flash[:error] = command.errors.message_list.join('\n')
      render :show
    end
  end

  def show
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed portfolio')

    @allocations = Allocations::GetActiveAllocations.call(portfolio: active_portfolio)
  end

  private

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
