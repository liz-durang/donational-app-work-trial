module Contributions
  class GetActiveTrial < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor)
        .where(trial_deactivated_at: nil)
        .where('trial_amount_cents > ?', 0)
        .where('start_at > ?', Time.zone.now)
        .order(created_at: :desc)
        .first
    end
  end
end
