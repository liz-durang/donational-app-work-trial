class PortfoliosController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def new
    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def create
    new_portfolio_command = Portfolios::CreateOrReplacePortfolio.run(
      donor: current_donor,
      donation_rate: current_donor.donation_rate,
      contribution_frequency: current_donor.contribution_frequency,
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

  def show
    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Viewed portfolio')

    track_analytics_event_via_browser('Goal: Viewed portfolio')

    @allocations = Allocations::GetActiveAllocations.call(portfolio: active_portfolio)
    @cause_areas = @allocations.map(&:organization).map(&:cause_area).uniq.map do |cause_area|
      I18n.t('title', scope: ['cause_areas', cause_area])
    end
  end

  private

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
