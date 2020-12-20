module Contributions
  class HasPreviousOrUpcomingContribution < ApplicationQuery
    def call(donor:)
      @donor = donor

      previous_contribution? || planned_contribution?
    end

    private

    def previous_contribution?
      Contribution.exists?(donor: @donor)
    end

    def planned_contribution?
      Subscription.exists?(donor: @donor, deactivated_at: nil)
    end
  end
end
