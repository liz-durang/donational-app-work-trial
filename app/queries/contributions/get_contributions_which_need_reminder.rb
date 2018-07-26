module Contributions
  class GetContributionsWhichNeedReminder < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call
      date = Date.today + 7.days
      @relation
        .where(deactivated_at: nil)
        .where(last_reminded_at: nil)
        .where(start_at: date.beginning_of_day..date.end_of_day)
    end
  end
end
