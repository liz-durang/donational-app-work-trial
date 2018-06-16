class OrganizationsController < ApplicationController
  def index
    @view_model = OpenStruct.new(
      organizations: recommended_organizations
    )
  end

  private

  def recommended_organizations
    Organizations::GetRecommendedOrganizations.call
  end

end
