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
      Payments::ChargeCustomer.run(
        customer_id: payment_method.payment_processor_customer_id,
        account_id: payment_processor_account_id,
        email: contribution.donor.email,
        donation_amount_cents: contribution.amount_cents,
        tips_cents: contribution.tips_cents,
        platform_fee_cents: payment_fees.platform_fee_cents
      ).tap do |command|
        if command.success?
          fee = command.result['balance_transaction']['fee_details'].detect { |fee| fee['type'] == 'stripe_fee' }
          contribution.update(receipt: command.result, processed_at: Time.zone.now, payment_processor_fees_cents: fee['amount'])
        else
          Appsignal.set_error(ChargeCustomerError.new(command.errors.to_json), contribution_id: contribution.id)
          contribution.update(receipt: command.errors.to_json, failed_at: Time.zone.now)
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

    def create_donations_based_on_active_allocations
      # TODO: Move this into a Donations::CreateDonationsFromContributionIntoPortfolio command
      Donation.transaction do
        Portfolios::GetActiveAllocations.call(portfolio: contribution.portfolio).each do |a|
          donation_amount_cents = (payment_fees.amount_donated_after_fees_cents * a.percentage / 100.0).floor
          Donation.create!(
            allocation: a,
            contribution: contribution,
            portfolio: a.portfolio,
            organization: a.organization,
            amount_cents: donation_amount_cents
          )
        end
      end
      Mutations::Outcome.new(true, nil, [], nil)
    end

    def send_tax_deductible_receipt
      portfolio_manager = Portfolios::GetPortfolioManager.call(portfolio: contribution.portfolio)

      ReceiptsMailer.send_receipt(contribution, payment_method, portfolio_manager).deliver_now
      Mutations::Outcome.new(true, nil, [], nil)
    end

    def payment_failed!
      add_error(:contribution, :payment_failed, "Could not charge customer '#{payment_method.payment_processor_customer_id}'")

      nil
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
