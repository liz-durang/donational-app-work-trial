module Contributions
  class GetFirstContribution < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor)
        .order(created_at: :asc)
        .first
    end
  end
end
