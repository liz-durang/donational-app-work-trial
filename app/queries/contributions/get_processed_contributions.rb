module Contributions
  class GetProcessedContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(portfolio: all_portfolios_for(donor))
        .where.not(processed_at: nil)
        .preload(:donations)
        .preload(:organizations)
        .order(created_at: :desc)
    end

    private

    def all_portfolios_for(donor)
      Portfolio.where(donor: donor)
    end
  end
end
