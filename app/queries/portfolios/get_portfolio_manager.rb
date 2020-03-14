module Portfolios
  class GetPortfolioManager < ApplicationQuery
    def initialize(relation = ManagedPortfolio.all)
      @relation = relation
    end

    def call(portfolio:)
      return nil unless portfolio

      @relation
        .where(portfolio: portfolio)
        .order(:id)
        .last
        .try(:partner)
    end
  end
end
