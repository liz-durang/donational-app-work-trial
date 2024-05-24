module Donors
  class DeactivateDonor < ApplicationCommand
    required do
      model :donor
    end

    def execute
      donor.update!(deactivated_at: Time.zone.now)

      deactivate_existing_subscriptions! if existing_subscriptions.any?
      deactivate_existing_trial_subscriptions!
    end

    private

    def existing_subscriptions
      @existing_subscriptions ||= Contributions::GetActiveSubscriptions.call(donor:)
    end

    def deactivate_existing_subscriptions!
      existing_subscriptions.update_all(deactivated_at: Time.zone.now)
    end

    def existing_trial_subscriptions
      @existing_trial_subscriptions ||= Subscription.where(donor:, trial_deactivated_at: nil)
                                                    .where('trial_amount_cents > ?', 0)
    end

    def deactivate_existing_trial_subscriptions!
      existing_trial_subscriptions.update_all(trial_deactivated_at: Time.zone.now)
    end
  end
end
