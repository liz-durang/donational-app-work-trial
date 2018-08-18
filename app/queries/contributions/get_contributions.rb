module Contributions
  class GetContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor)
        .preload(:donations)
        .preload(:organizations)
        .order(created_at: :desc)
    end
  end
end
