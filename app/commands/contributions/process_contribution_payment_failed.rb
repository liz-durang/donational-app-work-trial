# frozen_string_literal: true

module Contributions
  class ProcessContributionPaymentFailed < ApplicationCommand
    required do
      model :contribution
      string :errors
    end

    def validate
      ensure_contribution_not_processed!
    end

    def execute
      # Track error
      Appsignal.set_error(ChargeCustomerError.new(errors), contribution_id: contribution.id)

      # Update Contribution
      contribution.update(
        failed_at: Time.zone.now,
        receipt: errors,
        payment_status: :failed
      )

      # Send payment failed email
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)
      PaymentMethodsMailer.send_payment_failed(contribution, payment_method, partner).deliver_now

      # Send Zapier event
      TriggerPaymentFailedWebhook.perform_async(contribution.id, partner.id)

      # Update payment method retry count and cancel donation plan
      Payments::IncrementRetryCount.run(payment_method: payment_method)
      if active_subscription.present? && payment_method.retry_count_limit_reached?
        Contributions::DeactivateSubscription.run(subscription: active_subscription)
      end

      nil
    end

    private

    class ChargeCustomerError < RuntimeError; end

    # Validations
    def ensure_contribution_not_processed!
      return if contribution.processed_at.blank?

      add_error(:contribution, :already_processed, 'The payment has already been processed')
    end

    # Accessors
    def payment_method
      @payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end

    def active_subscription
      @active_contribution = Contributions::GetActiveSubscription.call(donor: contribution.donor)
    end
  end
end
