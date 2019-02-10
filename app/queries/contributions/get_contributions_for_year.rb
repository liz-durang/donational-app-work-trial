module Contributions
  class GetContributionsForYear < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:, year:)
      @relation
        .where(donor: donor)
        .where(processed_at: "#{year}-01-01".."#{year + 1}-01-01")
        .where(refunded_at: nil)
        .order(created_at: :desc)
    end
  end
end
