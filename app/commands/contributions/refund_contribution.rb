# frozen_string_literal: true

module Contributions
  class RefundContribution < ApplicationCommand
    required do
      model :contribution
    end

    def execute
      chain { refund_contribution_and_update_receipt! }
      chain { delete_donations! }
    end

    private

    class RefundChargeError < RuntimeError; end

    def refund_contribution_and_update_receipt!
      metadata = {
        donor_id: donor.id,
        contribution_id: contribution.id
      }

      outcome = if payment_type == 'charge'
                  Payments::RefundCharge.run(
                    account_id: payment_processor_account_id,
                    charge_id: payment_id,
                    metadata: metadata
                  )
                else
                  Payments::RefundPaymentIntent.run(
                    account_id: payment_processor_account_id,
                    payment_intent_id: payment_id,
                    metadata: metadata
                  )
                end

      outcome.tap do |command|
        if command.success?
          contribution.update(
            payment_status: :refunded,
            refunded_at: Time.zone.now
          )
        else
          refund_failed!(errors: command.errors.to_json)
        end
      end
    end

    def delete_donations!
      Donations::DeleteDonationsForContribution.run(contribution: contribution)
    end

    def refund_failed!(errors:)
      # Track error
      Sentry.capture_exception(RefundChargeError.new(errors), extra: { contribution_id: contribution.id })

      contribution.update(receipt: errors, failed_at: Time.zone.now)
    end

    def donor
      @donor = contribution.donor
    end

    def payment_id
      return nil if contribution.receipt.blank?

      @payment_id = contribution.receipt['id']
    end

    def payment_type
      return nil if contribution.receipt.blank?

      @payment_type = contribution.receipt['object']
    end

    def payment_processor_account_id
      @payment_processor_account_id = Payments::GetPaymentProcessorAccountId.call(donor: donor)
    end
  end
end
