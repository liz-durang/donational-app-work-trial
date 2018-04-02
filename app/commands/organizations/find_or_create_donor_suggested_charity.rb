module Organizations
  class FindOrCreateDonorSuggestedCharity < ApplicationCommand
    required do
      string :ein
      string :name
      model :suggested_by, class: Donor
    end

    def execute
      Organizations::GetOrganizationByEin.call(ein: ein) ||
        Organization.create!(
          ein: ein,
          name: name,
          suggested_by_donor: suggested_by
        )
    end
  end
end
