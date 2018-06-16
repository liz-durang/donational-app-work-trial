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
      chain { track_contribution_processed_event }

      nil
    end

    private

    def charge_customer_and_update_receipt!
      Payments::ChargeCustomer.run(
        customer_id: payment_method.payment_processor_customer_id,
        email: contribution.donor.email,
        donation_amount_cents: contribution.amount_cents,
        tips_cents: contribution.tips_cents,
        platform_fee_cents: platform_fee_cents
      ).tap do |command|
        if command.success?
          contribution.update(receipt: command.result, processed_at: Time.zone.now)
        else
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

    def platform_fee_cents
      # contribution.amount_cents * donor.partner&.platform_fee_percentage.to_f
      0
    end

    def payment_processor_fixed_fee
      30
    end

    def payment_processor_percentage_fee
      0.039
    end

    def total_charge_amount
      contribution.amount_cents + contribution.tips_cents
    end

    def fees
      total_charge_amount * payment_processor_percentage_fee + payment_processor_fixed_fee
    end

    def amount_donated_after_fees
      total_charge_amount - fees - contribution.tips_cents
    end

    def create_donations_based_on_active_allocations
      # TODO: Move this into a Donations::CreateDonationsFromContributionIntoPortfolio command
      Donation.transaction do
        Portfolios::GetActiveAllocations.call(portfolio: contribution.portfolio).each do |a|
          Donation.create!(
            allocation: a,
            contribution: contribution,
            portfolio: a.portfolio,
            organization: a.organization,
            amount_cents: (amount_donated_after_fees * a.percentage / 100.0).floor
          )
        end
      end
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

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end
  end
end
