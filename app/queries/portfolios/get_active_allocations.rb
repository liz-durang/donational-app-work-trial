module Portfolios
  class GetActiveAllocations < ApplicationQuery
    def initialize(relation = Allocation.all)
      @relation = relation
    end

    def call(portfolio:)
      @relation
        .where(portfolio: portfolio, deactivated_at: nil)
        .order(percentage: :desc, organization_ein: :asc)
        .includes([:organization])
    end
  end
end
