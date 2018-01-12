class AllocationsController < ApplicationController
  include Secured

  def update
    command = Allocations::UpdateAllocations.run(
      portfolio: active_portfolio,
      allocations: params[:allocations].values
    )

    if command.success?
      flash[:success] = 'Allocations saved!'
      Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed allocations')
      redirect_to edit_allocations_path
    else
      @allocations = params[:allocations].values.map { |a| Allocation.new(a) }
      flash[:error] = command.errors.message_list.join('\n')
      render :edit
    end
  end

  def edit
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed allocations')

    @allocations = Allocations::GetActiveAllocations.call(portfolio: active_portfolio)
  end

  private

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
