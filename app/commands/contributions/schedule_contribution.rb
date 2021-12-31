# frozen_string_literal: true

module Contributions
  class ScheduleContribution < ApplicationCommand
    required do
      model :donor
      model :portfolio
      model :partner
      integer :amount_cents, min: 100
      time :scheduled_at
    end

    optional do
      integer :tips_cents, min: 0, default: 0
      integer :partner_contribution_percentage, min: 0, default: 0
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

      Contribution.create!(
        donor: donor,
        portfolio: portfolio,
        partner: partner,
        amount_cents: amount_cents,
        tips_cents: tips_cents,
        scheduled_at: scheduled_at,
        external_reference_id: external_reference_id,
        processed_at: processed_at,
        receipt: receipt,
        partner_contribution_percentage: partner_contribution_percentage,
        amount_currency: partner.currency
      )
    end

    private

    def ensure_receipt_present_if_paid!
      return unless mark_as_paid

      add_error(:receipt, :not_found, "Receipt can't be nil") if receipt.nil?
    end
  end
end
