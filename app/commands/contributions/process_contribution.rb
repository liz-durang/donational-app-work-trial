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
      chain { create_donations_based_on_active_allocations }
      chain { send_tax_deductible_receipt }
      chain { track_contribution_processed_event }

      nil
    end

    private

    class ChargeCustomerError < RuntimeError; end

    def charge_customer_and_update_receipt!
      metadata = {
        donor_id: contribution.donor.id,
        portfolio_id: contribution.portfolio.id,
        contribution_id: contribution.id
      }
      Payments::ChargeCustomer.run(
        customer_id: payment_method.payment_processor_customer_id,
        account_id: payment_processor_account_id,
        email: contribution.donor.email,
        donation_amount_cents: contribution.amount_cents,
        tips_cents: contribution.tips_cents,
        currency: contribution.amount_currency,
        platform_fee_cents: payment_fees.platform_fee_cents,
        metadata: metadata
      ).tap do |command|
        if command.success?
          fee = command.result['balance_transaction']['fee_details'].detect { |fee| fee['type'] == 'stripe_fee' }
          contribution.update(
            receipt: command.result,
            processed_at: Time.zone.now,
            payment_processor_fees_cents: fee['amount'],
            payment_processor_account_id: payment_processor_account_id
          )
          TriggerContributionProcessedWebhook.perform_async(contribution.id, contribution.partner.id)
        else
          payment_failed!(errors: command.errors.to_json)
        end
      end
    end

    def ensure_donor_has_payment_method!
      return if payment_method.present?

      add_error(:payment_method, :not_found, 'The donor has no payment method')
    end

    def ensure_contribution_not_processed!
      return if contribution.processed_at.blank?

      add_error(:contribution, :already_processed, 'The payment has already been processed')
    end

    def payment_fees
      @payment_fees = Contributions::CalculatePaymentFees.call(contribution: contribution)
    end

    def payment_processor_account_id
      @payment_processor_account_id ||= Payments::GetPaymentProcessorAccountId.call(donor: contribution.donor)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end

    def active_recurring_contribution
      @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: contribution.donor)
    end

    def create_donations_based_on_active_allocations
      Donations::CreateDonationsFromContributionIntoPortfolio.run(
        contribution: contribution,
        donation_amount_cents: payment_fees.amount_donated_after_fees_cents
      )
    end

    def send_tax_deductible_receipt
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)
      ReceiptsMailer.send_receipt(contribution, payment_method, partner).deliver_now
      Mutations::Outcome.new(true, nil, [], nil)
    end

    def payment_failed!(errors:)
      # Track error
      Appsignal.set_error(ChargeCustomerError.new(errors), contribution_id: contribution.id)
      contribution.update(receipt: errors, failed_at: Time.zone.now)

      # Send payment failed email
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)
      PaymentMethodsMailer.send_payment_failed(contribution, payment_method, partner).deliver_now

      # Update payment method retry count and cancel donation plan
      Payments::IncrementRetryCount.run(payment_method: payment_method)
      if active_recurring_contribution.present? && payment_method.retry_count_limit_reached?
        Contributions::DeactivateRecurringContribution.run(recurring_contribution: active_recurring_contribution)
      end
    end

    def track_contribution_processed_event
      Analytics::TrackEvent.run(
        user_id: contribution.donor.id,
        event: 'Donation processed',
        traits: { revenue: contribution.amount_dollars, tip_dollars: contribution.tips_cents / 100 }
      )
    end
  end
end
