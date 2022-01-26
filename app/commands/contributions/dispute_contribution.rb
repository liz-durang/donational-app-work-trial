# frozen_string_literal: true

module Contributions
  class DisputeContribution < ApplicationCommand
    required do
      string :contribution_id
    end

    def execute
      chain { mark_contribution_as_disputed! }
      chain { delete_ungranted_donations! }
    end

    private

    def mark_contribution_as_disputed!
      outcome = contribution.update(
        payment_status: :disputed,
        disputed_at: Time.zone.now
      )

      Mutations::Outcome.new(outcome, nil, [], nil)
    end

    def delete_ungranted_donations!
      Donations::DeleteUngrantedDonationsForContribution.run(contribution: contribution)
    end

    def contribution
      @contribution ||= Contributions::GetContributionById.call(id: contribution_id)
    end
  end
end
