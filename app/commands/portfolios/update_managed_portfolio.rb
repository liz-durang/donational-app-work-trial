module Portfolios
  class UpdateManagedPortfolio < ApplicationCommand
    required do
      model :managed_portfolio
      model :donor
      string :title
      array :organizations
    end

    optional do
      boolean :featured
      boolean :archived
      string :description
      string :image
    end

    def execute
      Portfolio.transaction do
        find_or_create_organizations
        deactivate_existing_allocations
        add_organizations_to_portfolio
        update_managed_portoflio
      end

      nil
    end

    private

    def deactivate_existing_allocations
      managed_portfolio.portfolio.allocations.update_all(deactivated_at: Time.zone.now)
    end

    def find_or_create_organizations
      @organization_eins = []
      organizations.each do |organization|
        organization = Organizations::FindOrCreateDonorSuggestedCharity.run!(
          name: organization.split(",").first,
          ein: organization.split(",").last,
          suggested_by: donor
        )

        @organization_eins << organization.ein
      end
    end

    def add_organizations_to_portfolio
      Portfolios::AddOrganizationsAndRebalancePortfolio.run(
        portfolio: managed_portfolio.portfolio,
        organization_eins: @organization_eins
      )
    end

    def update_managed_portoflio
      managed_portfolio.update!(
        name: title,
        description: description,
        featured: featured,
        hidden_at: archived ? Time.zone.now : nil
      )
      managed_portfolio.image.attach(image) if image.present?
    end
  end
end
