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
    new_allocations = params[:allocations].values

    outcome = Flow.new
      .chain { Portfolios::CreateOrReplacePortfolio.run(donor: current_donor) }
      .chain { Portfolios::UpdateAllocations.run(portfolio: active_portfolio, allocations: new_allocations) }
      .run

    if outcome.success?
      redirect_to portfolio_path
    else
      redirect_to new_portfolio_path, alert: outcome.errors.message_list.join(' ')
    end
  end

  def show
    redirect_to onboarding_path unless active_portfolio.present?

    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed portfolio')

    track_analytics_event_via_browser('Goal: Viewed portfolio')

    @view_model = OpenStruct.new(
      donor_first_name: current_donor.first_name,
      organizations: organizations_by_cause_area,
      managed_portfolio: Portfolios::GetManagedPortfolio.call(portfolio: active_portfolio)
    )
  end

  private

  def recommended_allocations
    @recommended_allocations ||= Portfolios::GetRecommendedAllocations.call(donor: current_donor)
  end

  def organizations
    @organizations ||= Portfolios::GetActiveAllocations.call(portfolio: active_portfolio).map(&:organization)
  end

  def organizations_by_cause_area
    organizations.sort_by { |o| o.cause_area.to_s }
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
