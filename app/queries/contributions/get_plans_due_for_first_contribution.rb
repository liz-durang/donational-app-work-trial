module Contributions
  class GetPlansDueForFirstContribution < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      if date_before_fifteenth?
        one_time_contributions_only
      else
        all_first_time_contributions
      end
    end

    private

    def date_before_fifteenth?
      Time.zone.now.day < 15
    end

    def one_time_contributions_only
      @relation
        .where(deactivated_at: nil)
        .where(frequency: 'once')
        .where(start_at: Time.new(0)..Time.zone.now)
        .where(last_scheduled_at: nil)
    end

    def all_first_time_contributions
      @relation
        .where(deactivated_at: nil)
        .where(start_at: Time.new(0)..Time.zone.now)
        .where(last_scheduled_at: nil)
    end
  end
end
