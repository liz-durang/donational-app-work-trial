# frozen_string_literal: true

module Contributions
  class RefundContribution < ApplicationCommand
    required do
      model :contribution
    end

    def execute
      chain { refund_charge_and_update_receipt! }
      chain { delete_donations! }
    end

    private
    
    class RefundChargeError < RuntimeError; end

    def refund_charge_and_update_receipt!
      metadata = {
        donor_id: donor.id,
        contribution_id: contribution.id
      }
      Payments::RefundCharge.run(
        account_id: payment_processor_account_id,
        charge_id: charge_id
      ).tap do |command|
        if command.success?
          contribution.update(
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
      Appsignal.set_error(RefundChargeError.new(errors), contribution_id: contribution.id)
      contribution.update(receipt: errors, failed_at: Time.zone.now)
    end

    def donor
      @donor = contribution.donor
    end

    def charge_id
      @charge_id = contribution.receipt.present? ? contribution.receipt["id"] : nil
    end

    def payment_processor_account_id
      @payment_processor_account_id = Payments::GetPaymentProcessorAccountId.call(donor: donor)
    end
  end
end
