module Portfolios
  class CreateManagedPortfolio < ApplicationCommand
    required do
      model :partner
      model :donor
      string :title
      array :charities
    end

    optional do
      string :description
      string :image
    end

    def execute
      find_or_create_charities
      create_portfolio
      create_managed_portfolio

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
    end

    def create_portfolio
      @portfolio = Portfolio.create!.tap do |portfolio|
        Portfolios::AddOrganizationsAndRebalancePortfolio.run(
          portfolio: portfolio,
          organization_eins: @organization_eins
        )
      end
    end

    def create_managed_portfolio
      managed_portfolio = ManagedPortfolio.create(
        partner: partner,
        name: title,
        description: description || '',
        portfolio: @portfolio
      )
      managed_portfolio.image.attach(image) if image.present?
    end
  end
end
