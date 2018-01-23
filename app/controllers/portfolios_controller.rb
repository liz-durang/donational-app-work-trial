class PortfoliosController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def new
    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def create
    new_portfolio_command = Portfolios::CreateOrReplacePortfolio.run(
      donor: current_donor,
      contribution_amount_cents: current_donor.annual_income_cents
    )

    if new_portfolio_command.success?
      update_allocations_command = Allocations::UpdateAllocations.run(
        portfolio: active_portfolio,
        allocations: params[:allocations].values
      )
    end

    redirect_to portfolio_path
  end

  def show
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed portfolio')

    track_analytics_event_via_browser('Goal: Viewed portfolio')

    @portfolio = OpenStruct.new(
      donor_first_name: current_donor.first_name,
      organizations: organizations,
      cause_areas: organizations.map(&:cause_area).uniq
    )
  end

  private

  def organizations
    @organizations ||= Allocations::GetActiveAllocations.call(portfolio: active_portfolio).map(&:organization)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
