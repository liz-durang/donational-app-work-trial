module Contributions
  class GetTrialsDueForFirstContribution < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      return @relation.none unless date_after_fifteenth?

      @relation
        .where(trial_deactivated_at: nil)
        .where('trial_amount_cents > ?', 0)
        .where(trial_start_at: Time.new(0)..Time.zone.now)
        .where(trial_last_scheduled_at: nil)
        .where('start_at > ?', Time.zone.now)
    end

    private

    def date_after_fifteenth?
      Time.zone.now.day >= 15
    end
  end
end
