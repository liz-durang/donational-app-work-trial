module Subscriptions
  class CreateOrReplaceSubscription < Mutations::Command
    required do
      model :donor
      string :pay_in_frequency, default: 'monthly'
    end

    optional do
      float :donation_rate, min: 0, max: 1
      integer :annual_income_cents, min: 0
    end

    def execute
      deactivate_existing_subscriptions!
      Subscription.create!(inputs)
    end

    private

    def deactivate_existing_subscriptions!
      Subscriptions::GetActiveSubscriptions
        .call(donor: donor)
        .update_all(deactivated_at: Time.zone.now)
    end
  end
end
