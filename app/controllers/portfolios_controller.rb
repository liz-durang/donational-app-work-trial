class PortfoliosController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def new
    @portfolio = OpenStruct.new(
      donor_first_name: current_donor.first_name,
      allocations: recommended_allocations,
      cause_areas: recommended_allocations.map(&:organization).map(&:cause_area).uniq,
      diversity_text: current_donor.portfolio_diversity
    )
  end

  def create
    new_portfolio_command = Portfolios::CreateOrReplacePortfolio.run(
      donor: current_donor,
      contribution_frequency: current_donor.contribution_frequency
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
      organizations: organizations
    )
  end

  private

  def recommended_allocations
    @recommended_allocations ||= Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def organizations
    @organizations ||= Allocations::GetActiveAllocations.call(portfolio: active_portfolio).map(&:organization)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
