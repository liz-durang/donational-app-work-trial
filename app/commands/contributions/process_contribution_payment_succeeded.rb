# frozen_string_literal: true

module Contributions
  class ProcessContributionPaymentSucceeded < ApplicationCommand
    required do
      model :contribution
      string :receipt
    end

    def validate
      ensure_contribution_payment_not_succeeded!
    end

    def execute
      chain { update_contribution }
      chain { create_donations_based_on_active_allocations }
      chain { send_tax_deductible_receipt }
      chain { track_contribution_processed_event }

      nil
    end

    private

    # Accessors
    def payment_method
      @payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)
    end

    # Validations
    def ensure_contribution_payment_not_succeeded!
      return unless contribution.succeeded?

      add_error(:contribution, :payment_already_succeeded, 'The payment has already succeeded')
    end

    # Methods
    def update_contribution
      contribution.update(
        payment_status: :succeeded,
        receipt: JSON.parse(receipt)
      )

      Mutations::Outcome.new(true, nil, [], nil)
    end

    def create_donations_based_on_active_allocations
      Donations::CreateDonationsFromContributionIntoPortfolio.run(
        contribution: contribution,
        donation_amount_cents: contribution.amount_donated_after_fees_cents
      )
    end

    def send_tax_deductible_receipt
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)
      ReceiptsMailer.send_receipt(contribution, payment_method, partner).deliver_now

      Mutations::Outcome.new(true, nil, [], nil)
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
