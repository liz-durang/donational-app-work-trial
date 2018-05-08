require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class CreateOrReplaceRecurringContribution < ApplicationCommand
    required do
      model :donor
      model :portfolio
      symbol :frequency, default: :monthly, in: RecurringContribution.frequency.values
      integer :amount_cents, min: 0
      integer :platform_fee_cents, min: 0, default: 0
    end

    optional do
      date :start_at
    end

    def execute
      RecurringContribution.transaction do
        deactivate_existing_recurring_contributions!

        RecurringContribution.create!(
          donor: donor,
          portfolio: portfolio,
          frequency: frequency,
          start_at: start_at || Time.zone.now,
          amount_cents: amount_cents,
          platform_fee_cents: platform_fee_cents,
        )
      end

      nil
    end

    private

    def deactivate_existing_recurring_contributions!
      Contributions::GetActiveRecurringContributions
        .call(donor: donor)
        .update_all(deactivated_at: Time.zone.now)
    end

  end
end
