module Allocations
  class AddOrganizationAndRebalancePortfolio < ApplicationCommand
    required do
      model :portfolio
      model :organization
    end

    def execute
      chain AddOrganizationsAndRebalancePortfolio.run(
        portfolio: portfolio,
        organization_eins: [organization.ein]
      )

      nil
    end
  end
end
