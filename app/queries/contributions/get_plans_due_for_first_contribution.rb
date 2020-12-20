module Contributions
  class GetPlansDueForFirstContribution < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      if monthly_contributions_are_due?
        monthly_plans_due_contribution
          .or(non_monthly_plans_due_contribution)
      else
        non_monthly_plans_due_contribution
      end
    end

    private

    def monthly_contributions_are_due?
      Time.zone.now.day >= 15
    end

    def monthly_plans_due_contribution
      @relation
        .where(deactivated_at: nil)
        .where(frequency: 'monthly')
        .where(start_at: Time.new(0)..Time.zone.now)
        .where(last_scheduled_at: nil)
    end

    def non_monthly_plans_due_contribution
      @relation
        .where(deactivated_at: nil)
        .where.not(frequency: 'monthly')
        .where(start_at: Time.new(0)..Time.zone.now)
        .where(last_scheduled_at: nil)
    end
  end
end
