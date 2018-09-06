module Portfolios
  class GetPortfolioById < ApplicationQuery
    def initialize(relation = Portfolio.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
