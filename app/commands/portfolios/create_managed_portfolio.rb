module Portfolios
  class CreateManagedPortfolio < ApplicationCommand
    required do
      model :partner
      model :donor
      string :title
      string :description
    end

    optional do
      string :image
      boolean :featured
    end

    def execute
      managed_portfolio = ManagedPortfolio.create(
        partner:,
        name: title,
        description: description || '',
        featured: featured || false,
        portfolio: Portfolio.create!
      )
      managed_portfolio.image.attach(image) if image.present?

      managed_portfolio
    end
  end
end
