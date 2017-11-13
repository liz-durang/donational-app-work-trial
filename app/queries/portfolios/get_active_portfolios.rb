module Portfolios
  class GetActivePortfolios < ApplicationQuery
    def initialize(relation = Portfolio.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(donor: donor, deactivated_at: nil)
    end
  end
end
