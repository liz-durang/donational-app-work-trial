module PayOuts
  class ProcessPayOut < Mutations::Command
    required do
      model :pay_out
    end

    def validate
      return if pay_out.processed_at.blank?
      add_error(:pay_out, :already_processed, 'The payment has already been processed')
    end

    def execute
      PayOut.transaction do
        Checks::SendCheck.run(
          organization: pay_out.organization,
          amount_cents: pay_out.amount_cents
        )

        pay_out.update!(processed_at: Time.zone.now)
      end

      nil
    end
  end
end
