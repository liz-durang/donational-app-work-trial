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
        donor = contribution.donor

        payment = Payments::ChargeCustomer.run(
          customer_id: donor.payment_processor_customer_id,
          email: donor.email,
          amount_cents: contribution.amount_cents
        )

        return payment_failed! unless payment.success?

        contribution.update!(receipt: payment.result, processed_at: Time.zone.now)
        create_donations_based_on_active_allocations
      end

      nil
    end

    private

    def create_donations_based_on_active_allocations
      Allocations::GetActiveAllocations.call(portfolio: contribution.portfolio).each do |a|
        Donation.create!(
          allocation: a,
          contribution: contribution,
          portfolio: a.portfolio,
          organization: a.organization,
          amount_cents: (contribution.amount_cents * a.percentage / 100.0).floor
        )
      end
    end

    def payment_failed!
      add_error(:contribution, :payment_failed, "Could not charge customer '#{donor.payment_processor_customer_id}'")
      nil
    end
  end
end
