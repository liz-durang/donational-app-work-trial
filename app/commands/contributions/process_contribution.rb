module Contributions
  class ProcessContribution < Mutations::Command
    required do
      model :contribution
    end

    def validate
      ensure_contribution_not_processed!
      ensure_donor_has_payment_method!
    end

    def execute
      Contribution.transaction do
        payment = Payments::ChargeCustomer.run(
          customer_id: payment_method.customer_id,
          email: contribution.donor.email,
          amount_cents: contribution.amount_cents
        )

        return payment_failed! unless payment.success?

        contribution.update!(receipt: payment.result, processed_at: Time.zone.now)
        create_donations_based_on_active_allocations
      end

      nil
    end

    private

    def ensure_donor_has_payment_method!
      return if payment_method.present?

      add_error(:payment_method, :not_found, 'The donor has no payment method')
    end

    def ensure_contribution_not_processed!
      return if contribution.processed_at.blank?

      add_error(:contribution, :already_processed, 'The payment has already been processed')
    end

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
      add_error(
        :contribution,
        :payment_failed,
        "Could not charge customer '#{payment_method.customer_id}'"
      )
      nil
    end

    def payment_method
      @payment_method ||= PaymentMethods::GetActivePaymentMethod.call(donor: contribution.donor)
    end
  end
end
