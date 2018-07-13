module ManagedPortfolios
  class CreateManagedPortfolio < ApplicationCommand
    required do
      model :partner
      model :donor
      string :title
      string :description
      array :charities
    end

    def execute
      chain { find_or_create_charities }
      chain { create_portoflio }
      chain { create_managed_portfolio }

      nil
    end

    private

    def find_or_create_charities
      @organization_eins = []
      charities.each do |charity|
        organization = Organizations::FindOrCreateDonorSuggestedCharity.run!(
          name: charity.split(",").first,
          ein: charity.split(",").last,
          suggested_by: donor
        )

        @organization_eins << organization.ein
      end

      Mutations::Outcome.new(true, nil, [], nil)
    end

    def create_portoflio
      @portfolio = Portfolio.create!.tap do |portfolio|
        Portfolios::AddOrganizationsAndRebalancePortfolio.run(
          portfolio: portfolio,
          organization_eins: @organization_eins
        )
      end

      Mutations::Outcome.new(true, nil, [], nil)
    end

    def create_managed_portfolio
      ManagedPortfolio.create(
        partner: partner,
        name: title,
        description: description,
        portfolio: @portfolio
      )

      Mutations::Outcome.new(true, nil, [], nil)
    end
  end
end
