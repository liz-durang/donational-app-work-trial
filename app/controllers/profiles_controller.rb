class ProfilesController < ApplicationController
  layout 'minimal'

  def show
    not_found unless donor

    @profile = OpenStruct.new(
      name: donor.name,
      first_name: donor.first_name,
      video_url: "/path_to_video/#{donor.name.parameterize}",
      cause_areas: organizations.group_by(&:cause_area).map do |cause_area, organizations|
        OpenStruct.new(
          id: cause_area,
          title: I18n.t('title', scope: ['cause_areas', cause_area]),
          description: I18n.t('description', scope: ['cause_areas', cause_area]),
          organizations: organizations
        )
      end
    )
  end

  private

  def donor
    @donor ||= Donors::GetDonorByUsername.call(username: params[:username])
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: donor)
  end

  def allocations
    @allocations ||= Allocations::GetActiveAllocations.call(portfolio: active_portfolio)
  end

  def organizations
    @organizations ||= allocations.map(&:organization)
  end
end
