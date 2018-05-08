module Allocations
  class AddOrganizationAndRebalancePortfolio < ApplicationCommand
    required do
      model :portfolio
      model :organization
    end

    def execute
      chain do
        AddOrganizationsAndRebalancePortfolio.run(
          portfolio: portfolio,
          organization_eins: [organization.ein]
        )
      end

      nil
    end
  end
end
