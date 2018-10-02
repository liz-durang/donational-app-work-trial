module Contributions
  class ProcessDonationPlans < ApplicationCommand
    def execute
      # Contributions::GetRecurringContributionsByFrequency does not return recurring contributions with start_date in the future
      # This is how we don’t schedule monthly/quarterly/annual donations that have a future start_date

      # To auto-schedule plans on their start date, we first check what is the last contribution date for that donation plan
      # If that date is nil, it means that start_date was scheduled in the future, so we check_if_starts_today_and_schedule_contribution

      # To not schedule monthly donations in the first month of the plan, we use next_15th_of_the_month_after(earliest_monthly)

      # Process monthly donation plans
      monthly_recurring_contributions.each do |recurring_contribution|
        if last_contribution_date(recurring_contribution).present?
          earliest_monthly = [
            last_contribution_date(recurring_contribution).at_beginning_of_month + 1.month,
            recurring_contribution.start_at.at_beginning_of_month + 1.month
          ].max

          if Date.today == next_15th_of_the_month_after(earliest_monthly)
            schedule_contribution!(recurring_contribution: recurring_contribution)
          end
        else
          check_if_starts_today_and_schedule_contribution!(recurring_contribution)
        end
      end

      # Process quarterly and annually donation plans
      quarterly_recurring_contributions.each do |recurring_contribution|
        if last_contribution_date(recurring_contribution).present?
          if Date.today == last_contribution_date(recurring_contribution).next_quarter.at_beginning_of_quarter
            schedule_contribution!(recurring_contribution: recurring_contribution)
          end
        else
          check_if_starts_today_and_schedule_contribution!(recurring_contribution)
        end
      end

      annually_recurring_contributions.each do |recurring_contribution|
        if last_contribution_date(recurring_contribution).present?
          if Date.today == Date.new(last_contribution_date(recurring_contribution).year + 1, last_contribution_date(recurring_contribution).month, 1)
            schedule_contribution!(recurring_contribution: recurring_contribution)
          end
        else
          check_if_starts_today_and_schedule_contribution!(recurring_contribution)
        end
      end

      nil
    end

    private

    def monthly_recurring_contributions
      Contributions::GetRecurringContributionsByFrequency.call(frequency: 'monthly')
    end

    def quarterly_recurring_contributions
      Contributions::GetRecurringContributionsByFrequency.call(frequency: 'quarterly')
    end

    def annually_recurring_contributions
      Contributions::GetRecurringContributionsByFrequency.call(frequency: 'annually')
    end

    def last_contribution_date(recurring_contribution)
      Contributions::GetLastContributionDateByDonationPlan.call(recurring_contribution: recurring_contribution)
    end

    def next_15th_of_the_month_after(date)
      month = date.day < 15 ? date.month : date.next_month.month
      Date.new(date.year, month, 15)
    end

    def schedule_contribution!(recurring_contribution:)
      Contributions::ScheduleContribution.run(
        donor: recurring_contribution.donor,
        portfolio: recurring_contribution.portfolio,
        amount_cents: recurring_contribution.amount_cents,
        tips_cents: recurring_contribution.tips_cents,
        scheduled_at: Time.zone.now
      )
    end

    def check_if_starts_today_and_schedule_contribution!(recurring_contribution)
      if Date.today == recurring_contribution.start_at.to_date
        schedule_contribution!(recurring_contribution: recurring_contribution)
      end
    end
  end
end
