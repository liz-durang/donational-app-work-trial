module Contributions
  class GetLastContributionDateByDonationPlan < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(recurring_contribution:)
      @relation
        .where(donor: recurring_contribution.donor)
        .where(portfolio: recurring_contribution.portfolio)
        .order(scheduled_at: :desc)
        .first&.scheduled_at&.to_date
    end
  end
end
