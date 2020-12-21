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
    end

    def execute
      managed_portfolio = ManagedPortfolio.create(
        partner: partner,
        name: title,
        description: description || '',
        portfolio: Portfolio.create!
      )
      managed_portfolio.image.attach(image) if image.present?

      managed_portfolio
    end
  end
end
