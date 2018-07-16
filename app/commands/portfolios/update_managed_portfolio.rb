module Portfolios
  class UpdateManagedPortfolio < ApplicationCommand
    required do
      model :managed_portfolio
      model :donor
      string :title
      string :description
      array :charities
    end

    def execute
      deactivate_existing_portfolio
      find_or_create_charities
      create_portoflio
      update_managed_portoflio

      nil
    end

    private

    def deactivate_existing_portfolio
      managed_portfolio.portfolio.update!(deactivated_at: Time.zone.now)
    end

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
    end

    def create_portoflio
      @portfolio = Portfolio.create!.tap do |portfolio|
        Portfolios::AddOrganizationsAndRebalancePortfolio.run(
          portfolio: portfolio,
          organization_eins: @organization_eins
        )
      end
    end

    def update_managed_portoflio
      managed_portfolio.update!(
        name: title,
        description: description,
        portfolio: @portfolio
      )
    end
  end
end
