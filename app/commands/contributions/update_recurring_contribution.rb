require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class UpdateRecurringContribution < ApplicationCommand
    required do
      model :recurring_contribution
    end

    optional do
      symbol :frequency, default: :monthly, in: RecurringContribution.frequency.values
      integer :amount_cents, min: 0
    end

    def execute
      recurring_contribution.update!(updateable_attributes)

      nil
    end

    def updateable_attributes
      inputs.except(:recurring_contribution)
    end
  end
end
