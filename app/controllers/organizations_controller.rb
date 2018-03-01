class OrganizationsController < ApplicationController
  def index
    @model = OpenStruct.new(
      organizations: recommended_organizations
    )
  end

  private

  def recommended_organizations
    Organizations::GetRecommendedOrganizations.call
  end

end
