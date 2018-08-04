class AllocationsController < ApplicationController
  include Secured

  def new
    @view_model = OpenStruct.new(
      portfolio: active_portfolio,
      addable_organizations: organizations_available_to_add_to_portfolio
    )
  end

  def create
    organization = Organizations::FindOrCreateDonorSuggestedCharity.run!(
      ein: params[:organization][:ein],
      name: params[:organization][:name],
      suggested_by: current_donor
    )

    Portfolios::AddOrganizationAndRebalancePortfolio.run!(
      portfolio: active_portfolio,
      organization: organization
    )

    flash[:success] = "#{organization.name} has been added to your portfolio"
    redirect_to portfolio_path
  end

  def update
    command = Portfolios::UpdateAllocations.run(
      portfolio: active_portfolio,
      allocations: params[:allocations].values
    )

    if command.success?
      flash[:success] = 'Allocations saved!'
      redirect_to edit_allocations_path
    else
      @allocations = params[:allocations].values.map { |a| Allocation.new(a) }
      flash[:error] = command.errors.message_list.join('\n')
      render :edit
    end
  end

  def edit
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed allocations')

    @view_model = OpenStruct.new(
      allocations: Portfolios::GetActiveAllocations.call(portfolio: active_portfolio),
      managed_portfolio?: portfolio_manager.present?,
      portfolio_manager_name: portfolio_manager.try(:name)
    )
  end

  private

  def portfolio_manager
    @portfolio_manager ||= Portfolios::GetPortfolioManager.call(portfolio: active_portfolio)
  end

  def organizations_available_to_add_to_portfolio
    Organizations::GetRecommendedOrganizationsThatAreNotInPortfolio.call(portfolio: active_portfolio)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
