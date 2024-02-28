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

      charge_command = nil

      if payment_method_located_on_a_connected_account?
        charge_command = Payments::ConnectedAccount::ChargeCustomer
      else
        # In this branch, the payment method should be expected to be on the Stripe platform account. This is the case
        # for card and US bank account payment methods created before we used Stripe Checkout Sessions.
        charge_command = case payment_method
                         when PaymentMethods::Card
                           Payments::PlatformAccount::ChargeCustomerCard
                         when PaymentMethods::BankAccount
                           Payments::PlatformAccount::ChargeCustomerUsBankAccount
                         end
      end

      outcome = charge_command.run(
        account_id: payment_processor_account_id,
        currency: contribution.amount_currency,
        donation_amount_cents: contribution.amount_cents,
        metadata:,
        payment_method:,
        platform_fee_cents:,
        tips_cents: contribution.tips_cents
      )

      outcome.tap do |command|
        if command.success?
          contribution.update(
            receipt: command.result[:receipt],
            processed_at: Time.zone.now,
            platform_fees_cents: platform_fee_cents,
            payment_processor_fees_cents: command.result[:payment_processor_fees_cents],
            payment_processor_account_id:,
            payment_status: :pending
          )
          # We need to update donor_advised_fund_fees_cents and amount_donated_after_fees_cents after processed_at is set.
          contribution.update(
            donor_advised_fund_fees_cents: payment_fees.donor_advised_fund_fees_cents,
            amount_donated_after_fees_cents: payment_fees.amount_donated_after_fees_cents
          )
          TriggerContributionProcessedWebhook.perform_async(contribution.id, contribution.partner.id)
        else
          Contributions::ProcessContributionPaymentFailed.run(contribution:,
                                                              errors: command.errors.to_json)
        end
      end
    end

    def payment_method_located_on_a_connected_account?
      # Stripe accounts may be 'platform' accounts or 'connected' accounts.
      # The type of account on which the payment processor's record of the payment method is located, which may differ
      # from the partner to which the Donational PaymentMethod record is associated (particularly in the case of card and
      # US bank account payment methods created before we used Stripe Checkout Sessions, which are located on the payment
      # processor 'platform' account, while the Donational PaymentMethod record will be associated to the Partner.)
      @payment_method_is_located_on_a_connected_account ||= Stripe::PaymentMethod.retrieve(
        payment_method.payment_processor_source_id,
        { stripe_account: payment_processor_account_id }
      ).present?
    rescue Stripe::InvalidRequestError # No payment method found for this id and account.
      false
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
      @payment_fees = Contributions::CalculatePaymentFees.call(contribution:)
    end

    def payment_processor_account_id
      @payment_processor_account_id ||= Payments::GetPaymentProcessorAccountId.call(donor: contribution.donor)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end
  end
end
