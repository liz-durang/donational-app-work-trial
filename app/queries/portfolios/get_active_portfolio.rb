module Portfolios
  class GetActivePortfolio < ApplicationQuery
    def initialize(relation = SelectedPortfolio.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor, deactivated_at: nil)
        .order(:id)
        .last
        &.portfolio
    end
  end
end
