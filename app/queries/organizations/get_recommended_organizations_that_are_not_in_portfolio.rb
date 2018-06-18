module Organizations
  class GetRecommendedOrganizationsThatAreNotInPortfolio < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(portfolio:)
      recommendable_organizations.where.not(ein: organization_eins_in(portfolio))
    end

    def recommendable_organizations
      GetRecommendedOrganizations.new(@relation).call
    end

    def organization_eins_in(portfolio)
      Portfolios::GetActiveAllocations
        .call(portfolio: portfolio)
        .map(&:organization_ein)
    end
  end
end
