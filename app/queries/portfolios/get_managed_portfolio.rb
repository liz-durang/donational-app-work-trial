module Portfolios
  class GetManagedPortfolio < ApplicationQuery
    def initialize(relation = ManagedPortfolio.all)
      @relation = relation
    end

    def call(portfolio:)
      @relation
        .where(portfolio: portfolio)
        .order(:id)
        .last
    end
  end
end
