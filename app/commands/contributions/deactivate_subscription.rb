require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class DeactivateSubscription < ApplicationCommand
    required do
      model :subscription
    end

    def execute
      subscription.update!(deactivated_at: Time.zone.now)

      send_confirmation_email!
      TriggerSubscriptionWebhook.perform_async('cancel', subscription.partner.id, subscription.id)

      nil
    end

    private

    def send_confirmation_email!
      payment_method = Payments::GetActivePaymentMethod.call(donor: subscription.donor)
      partner = Partners::GetPartnerForDonor.call(donor: subscription.donor)

      ConfirmationsMailer.send_confirmation(
        subscription: subscription,
        payment_method: payment_method,
        partner: partner,
        cancelation: true
      ).deliver_now
    end
  end
end
