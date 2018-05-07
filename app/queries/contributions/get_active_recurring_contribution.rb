module Contributions
  class GetActiveRecurringContribution < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call(donor:)
      GetActiveRecurringContributions.new(@relation).call(donor: donor).first
    end
  end
end
