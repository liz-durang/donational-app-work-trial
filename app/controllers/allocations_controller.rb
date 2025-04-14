class AllocationsController < ApplicationController
  include Secured

  def new
    @view_model = OpenStruct.new(
      portfolio: active_portfolio,
      addable_organizations: organizations_available_to_add_to_portfolio
    )
  end

  def edit
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed allocations')

    edit_view_model
  end

  def create
    pipeline = Flow.new
    pipeline.chain do
      Organizations::FindOrCreateDonorSuggestedCharity.run(
        ein: params[:organization][:ein],
        name: params[:organization][:name],
        suggested_by: current_donor
      )
    end
    pipeline.chain { convert_managed_portfolio_into_custom_portfolio! } if managed_portfolio?
    pipeline.chain do
      Portfolios::AddOrganizationAndRebalancePortfolio.run(
        portfolio: active_portfolio,
        organization: Organizations::GetOrganizationByEin.call(ein: params[:organization][:ein])
      )
    end
    outcome = pipeline.run

    organization = Organizations::GetOrganizationByEin.call(ein: params[:organization][:ein])

    if outcome.success?
      flash[:success] = "#{organization.name} has been added to your portfolio"
    else
      flash[:error] = outcome.errors.message_list.join('. ')
    end

    redirect_to portfolio_path
  end

  def update
    pipeline = Flow.new
    pipeline.chain { convert_managed_portfolio_into_custom_portfolio! } if managed_portfolio?
    pipeline.chain do
      Portfolios::UpdateAllocations.run(
        portfolio: active_portfolio,
        allocations: params[:allocations].values
      )
    end

    outcome = pipeline.run

    if outcome.success?
      flash[:success] = 'Allocations saved!'
      redirect_to edit_allocations_path
    else
      @allocations = params[:allocations].values.map do |a|
        Allocation.new(organization_ein: a[:organization_ein], percentage: a[:percentage])
      end
      flash[:error] = outcome.errors.message_list.join('\n')
      edit_view_model
      render :edit
    end
  end

  private

  def convert_managed_portfolio_into_custom_portfolio!
    managed_portfolio_allocations = Portfolios::GetActiveAllocations.call(portfolio: active_portfolio)
    cmd = Portfolios::CreateOrReplacePortfolio.run(donor: current_donor)

    if cmd.success?
      Portfolios::UpdateAllocations.run!(
        portfolio: active_portfolio,
        allocations: managed_portfolio_allocations.as_json(only: %i[organization_ein percentage])
      )

      active_subscription.update!(portfolio: active_portfolio) if active_subscription
    end

    cmd
  end

  def managed_portfolio?
    portfolio_manager.present?
  end

  def portfolio_manager
    @portfolio_manager ||= Portfolios::GetPortfolioManager.call(portfolio: active_portfolio)
  end

  def organizations_available_to_add_to_portfolio
    Organizations::GetRecommendedOrganizationsThatAreNotInPortfolio.call(portfolio: active_portfolio)
  end

  def active_portfolio
    Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_subscription
    Contributions::GetActiveSubscription.call(donor: current_donor)
  end

  def edit_view_model
    @view_model = OpenStruct.new(
      allocations: Portfolios::GetActiveAllocations.call(portfolio: active_portfolio),
      managed_portfolio?: managed_portfolio?,
      portfolio_manager_name: portfolio_manager.try(:name)
    )
  end
end
