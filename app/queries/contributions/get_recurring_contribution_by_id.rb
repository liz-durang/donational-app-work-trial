module Contributions
  class GetRecurringContributionById  < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
