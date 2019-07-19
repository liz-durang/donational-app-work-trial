module Contributions
  class ScheduleContribution < ApplicationCommand
    required do
      model :donor
      model :portfolio
      integer :amount_cents, min: 100
      time :scheduled_at
    end

    optional do
      integer :tips_cents, min: 0, default: 0
      string :external_reference_id
      boolean :mark_as_paid
      hash :receipt do
        string :method
        string :account
        string :memo
        string :transfer_date
      end
    end

    def validate
      ensure_receipt_present_if_paid!
    end

    def execute
      processed_at = mark_as_paid ? Time.zone.now : nil

      contribution = Contribution.create!(
        donor: donor,
        portfolio: portfolio,
        amount_cents: amount_cents,
        tips_cents: tips_cents,
        scheduled_at: scheduled_at,
        external_reference_id: external_reference_id,
        processed_at: processed_at,
        receipt: receipt
      )
    end

    private

    def ensure_receipt_present_if_paid!
      return unless mark_as_paid

      add_error(:receipt, :not_found, "Receipt can't be nil") if receipt.nil?
    end
  end
end
