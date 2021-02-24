module Donors
  class DeactivateDonor < ApplicationCommand
    required do
      model :donor
    end

    def execute
      donor.update!(deactivated_at: Time.zone.now)

      deactivate_existing_subscriptions! if existing_subscriptions.any?
    end

    private

    def existing_subscriptions
      @existing_subscriptions ||= Contributions::GetActiveSubscriptions.call(donor: donor)
    end

    def deactivate_existing_subscriptions!
      existing_subscriptions.update_all(deactivated_at: Time.zone.now)
    end
  end
end
