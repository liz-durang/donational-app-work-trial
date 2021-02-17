# frozen_string_literal: true

module Contributions
  class ProcessContribution < ApplicationCommand
    required do
      model :contribution
    end

    def validate
      ensure_contribution_not_processed!
      ensure_donor_has_payment_method!
    end

    def execute
      chain { charge_customer_and_update_receipt! }

      nil
    end

    private

    def charge_customer_and_update_receipt!
      platform_fee_cents = payment_fees.platform_fee_cents
      metadata = {
        donor_id: contribution.donor.id,
        portfolio_id: contribution.portfolio.id,
        contribution_id: contribution.id
      }

      charge_command = if payment_method.is_a?(PaymentMethods::Card)
                         Payments::ChargeCustomerCard
                       else
                         Payments::ChargeCustomerBankAccount
                       end

      outcome = charge_command.run(
                  account_id: payment_processor_account_id,
                  currency: contribution.amount_currency,
                  donation_amount_cents: contribution.amount_cents,
                  metadata: metadata,
                  payment_method: payment_method,
                  platform_fee_cents: platform_fee_cents,
                  tips_cents: contribution.tips_cents
                )

      outcome.tap do |command|
        if command.success?
          contribution.update(
            receipt: command.result[:receipt],
            processed_at: Time.zone.now,
            platform_fees_cents: platform_fee_cents,
            payment_processor_fees_cents: command.result[:payment_processor_fees_cents],
            payment_processor_account_id: payment_processor_account_id,
            payment_status: :pending
          )
          # We need to update donor_advised_fund_fees_cents and amount_donated_after_fees_cents after processed_at is set.
          contribution.update(
            donor_advised_fund_fees_cents: payment_fees.donor_advised_fund_fees_cents,
            amount_donated_after_fees_cents: payment_fees.amount_donated_after_fees_cents
          )
          TriggerContributionProcessedWebhook.perform_async(contribution.id, contribution.partner.id)
        else
          Contributions::ProcessContributionPaymentFailed.run(contribution: contribution, errors: command.errors.to_json)
        end
      end
    end

    # Validations
    def ensure_donor_has_payment_method!
      return if payment_method.present?

      add_error(:payment_method, :not_found, 'The donor has no payment method')
    end

    def ensure_contribution_not_processed!
      return if contribution.processed_at.blank?

      add_error(:contribution, :already_processed, 'The payment has already been processed')
    end

    # Accessors
    def payment_fees
      @payment_fees = Contributions::CalculatePaymentFees.call(contribution: contribution)
    end

    def payment_processor_account_id
      @payment_processor_account_id ||= Payments::GetPaymentProcessorAccountId.call(donor: contribution.donor)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end
  end
end
