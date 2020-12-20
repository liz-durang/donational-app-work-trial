module Contributions
  class GetLastContributionDateByDonationPlan < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(subscription:)
      @relation
        .where(donor: subscription.donor)
        .where(portfolio: subscription.portfolio)
        .order(scheduled_at: :desc)
        .first&.scheduled_at&.to_date
    end
  end
end
