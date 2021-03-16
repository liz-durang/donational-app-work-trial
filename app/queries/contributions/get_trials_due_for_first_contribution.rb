module Contributions
  class GetTrialsDueForFirstContribution < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      monthly_contributions_are_due? ? trials_due_contribution : @relation.none
    end

    private

    def monthly_contributions_are_due?
      Time.zone.now.day >= 15
    end

    def trials_due_contribution
      @relation
        .where(trial_deactivated_at: nil)
        .where('trial_amount_cents > ?', 0)
        .where(trial_start_at: Time.new(0)..Time.zone.now)
        .where(trial_last_scheduled_at: nil)
        .where('start_at > ?', Time.zone.now)
    end
  end
end
