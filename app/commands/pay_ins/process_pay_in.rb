require_dependency Rails.root.join('lib', 'dummy_payment_processor')

module PayIns
  class ProcessPayIn < Mutations::Command
    required do
      model :pay_in
      duck :payment_processor,
           methods: [:withdraw_from_donor!],
           default: DummyPaymentProcessor.new
    end

    def validate
      return if pay_in.processed_at.blank?
      add_error(:pay_in, :already_processed, 'The payment has already been processed')
    end

    def execute
      receipt = payment_processor.withdraw_from_donor!(
        donor: pay_in.donor,
        amount_cents: pay_in.amount_cents
      )

      PayIn.transaction do
        # TODO: if payment fails, persist the receipt but leave processed_at blank
        pay_in.update!(receipt: receipt, processed_at: Time.zone.now)

        create_donations_based_on_active_allocations
      end

      nil
    end

    private

    def create_donations_based_on_active_allocations
      Allocations::GetActiveAllocations.call(subscription: pay_in.subscription).each do |a|
        Donation.create!(
          allocation: a,
          pay_in: pay_in,
          subscription: a.subscription,
          organization: a.organization,
          amount_cents: (pay_in.amount_cents * a.percentage / 100.0).floor
        )
      end
    end
  end
end
