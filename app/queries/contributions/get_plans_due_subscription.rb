module Contributions
  class GetPlansDueSubscription < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      if monthly_contributions_are_due?
        monthly_plans_due_contribution
          .or(quarterly_plans_due_contribution
            .or(annual_plans_due_contribution))
      else
        quarterly_plans_due_contribution.or(annual_plans_due_contribution)
      end
    end

    private

    def monthly_contributions_are_due?
      Time.zone.now.day >= 15
    end

    def monthly_plans_due_contribution
      end_of_last_month = Time.zone.now.last_month.at_end_of_month
      @relation
        .where(deactivated_at: nil)
        .where(frequency: 'monthly')
        .where(start_at: Time.new(0)..end_of_last_month)
        .where(last_scheduled_at: Time.new(0)..end_of_last_month)
    end

    def quarterly_plans_due_contribution
      end_of_last_quarter = Time.zone.now.last_quarter.at_end_of_quarter
      @relation
        .where(deactivated_at: nil)
        .where(frequency: 'quarterly')
        .where(start_at: Time.new(0)..end_of_last_quarter)
        .where(last_scheduled_at: Time.new(0)..end_of_last_quarter)
    end

    def annual_plans_due_contribution
      one_year_ago = Time.now - 1.year
      @relation
        .where(deactivated_at: nil)
        .where(frequency: 'annually')
        .where(start_at: Time.new(0)..one_year_ago)
        .where(last_scheduled_at: Time.new(0)..one_year_ago)
    end
  end
end
