module Contributions
  class GetTrialsDueSubscription < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      return @relation.none unless date_after_fifteenth?

      end_of_last_month = Time.zone.now.last_month.at_end_of_month

      @relation
        .where(trial_deactivated_at: nil)
        .where('trial_amount_cents > ?', 0)
        .where(trial_start_at: Time.new(0)..end_of_last_month)
        .where(trial_last_scheduled_at: Time.new(0)..end_of_last_month)
        .where('start_at > ?', Time.zone.now)
    end

    private

    def date_after_fifteenth?
      Time.zone.now.day >= 15
    end
  end
end
