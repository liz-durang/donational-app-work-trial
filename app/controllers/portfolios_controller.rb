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
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed portfolio')

    track_analytics_event_via_browser('Goal: Viewed portfolio')

    @view_model = OpenStruct.new(
      donor_first_name: current_donor.first_name,
      organizations: organizations_by_cause_area,
      managed_portfolio?: portfolio_manager.present?,
      portfolio_manager_name: portfolio_manager.try(:name),
      recurring_contribution: active_recurring_contribution,
      first_contribution: Contributions::GetFirstContribution.call(donor: current_donor),
      show_modal: params[:show_modal].to_s == 'true',
      show_blank_state: active_portfolio.blank?
    )
  end

  private

  def portfolio_manager
    @portfolio_manager ||= Portfolios::GetPortfolioManager.call(portfolio: active_portfolio)
  end

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

  def active_recurring_contribution
    @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: current_donor)
  end
end
