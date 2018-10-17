require 'rails_helper'

RSpec.describe Contributions::ScheduleContributionsForPastDuePlans do
  include ActiveSupport::Testing::TimeHelpers

  let(:plan1) { build(:recurring_contribution) }
  let(:plan2) { build(:recurring_contribution) }
  let(:plan3) { build(:recurring_contribution) }

  let(:plans_needing_first_contribution) { [plan1] }
  let(:plans_needing_recurring_contribution) { [plan2, plan3] }

  context 'when there are plans that are due to be scheduled' do
    before do
      expect(Contributions::GetPlansDueForFirstContribution)
        .to receive(:call)
        .and_return([plan1])
      expect(Contributions::GetPlansDueRecurringContribution)
        .to receive(:call)
        .and_return([plan2, plan3])
    end

    it 'schedules a contribution for each plan' do
      freeze_time do
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(recurring_contribution: plan1, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(recurring_contribution: plan2, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(recurring_contribution: plan3, scheduled_at: Time.zone.now)

        Contributions::ScheduleContributionsForPastDuePlans.run
      end
    end
  end
end
