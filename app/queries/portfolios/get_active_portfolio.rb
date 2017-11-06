module Portfolios
  class GetActivePortfolio < ApplicationQuery
    def initialize(relation = Portfolio.all)
      @relation = relation
    end

    def call(donor:)
      GetActivePortfolios.new(@relation).call(donor: donor).first
    end
  end
end
