module Contributions
  class ProcessContribution < Mutations::Command
    required do
      model :contribution
    end

    def validate
      return if contribution.processed_at.blank?
      add_error(:contribution, :already_processed, 'The payment has already been processed')
    end

    def execute
      Contribution.transaction do
        receipt = Withdrawals::WithdrawFromDonor.run(
          donor: contribution.donor,
          amount_cents: contribution.amount_cents
        )

        # TODO: if payment fails, persist the receipt but leave processed_at blank
        contribution.update!(receipt: receipt, processed_at: Time.zone.now)

        create_donations_based_on_active_allocations
      end

      nil
    end

    private

    def create_donations_based_on_active_allocations
      Allocations::GetActiveAllocations.call(subscription: contribution.subscription).each do |a|
        Donation.create!(
          allocation: a,
          contribution: contribution,
          subscription: a.subscription,
          organization: a.organization,
          amount_cents: (contribution.amount_cents * a.percentage / 100.0).floor
        )
      end
    end
  end
end
