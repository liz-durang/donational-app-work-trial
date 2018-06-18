require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class DeactivateRecurringContribution < ApplicationCommand
    required do
      model :recurring_contribution
    end

    def execute
      recurring_contribution.update!(deactivated_at: Time.zone.now)

      nil
    end
  end
end
