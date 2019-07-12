module Organizations
  class FindOrCreateDonorSuggestedCharity < ApplicationCommand
    required do
      string :ein
      model :suggested_by, class: Donor
    end

    def execute
      Organizations::GetOrganizationByEin.call(ein: ein) || create_organization_from_searchable_organization
    end

    def create_organization_from_searchable_organization
      if searchable_organization
        Organization.create!(
          ein: searchable_organization.formatted_ein,
          name: searchable_organization.formatted_name,
          suggested_by_donor: suggested_by
        )
      else
        add_error(:organization, :not_found, "Could not find an organization with ein #{ein}")
      end
    end

    def searchable_organization
      @searchable_organization ||= SearchableOrganization.find_by(ein: ein.delete('-'))
    end
  end
end
