module Contributions
  class GetProcessedContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor)
        .where.not(processed_at: nil)
        .preload(:donations)
        .preload(:organizations)
        .order(created_at: :desc)
    end
  end
end
