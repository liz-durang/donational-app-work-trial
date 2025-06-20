require 'rails_helper'

RSpec.describe Contributions::ScheduleContributionsForPastDuePlans do
  include ActiveSupport::Testing::TimeHelpers

  let(:plan1) { build(:subscription) }
  let(:plan2) { build(:subscription) }
  let(:plan3) { build(:subscription) }

  let(:plans_needing_first_contribution) { [plan1] }
  let(:plans_needing_subscription) { [plan2, plan3] }

  let(:trial1) { build(:subscription) }
  let(:trial2) { build(:subscription) }
  let(:trial3) { build(:subscription) }

  let(:trials_needing_first_contribution) { [trial1] }
  let(:trials_needing_subscription) { [trial2, trial3] }

  context 'when there are plans that are due to be scheduled' do
    before do
      expect(Contributions::GetPlansDueForFirstContribution)
        .to receive(:call)
        .and_return([plan1])
      expect(Contributions::GetPlansDueSubscription)
        .to receive(:call)
        .and_return([plan2, plan3])
    end

    it 'schedules a contribution for each plan' do
      freeze_time do
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(subscription: plan1, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(subscription: plan2, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForPlan)
          .to receive(:run)
          .with(subscription: plan3, scheduled_at: Time.zone.now)

        Contributions::ScheduleContributionsForPastDuePlans.run
      end
    end
  end

  context 'when there are trials that are due to be scheduled' do
    before do
      expect(Contributions::GetTrialsDueForFirstContribution)
        .to receive(:call)
        .and_return(trials_needing_first_contribution)
      expect(Contributions::GetTrialsDueSubscription)
        .to receive(:call)
        .and_return(trials_needing_subscription)
    end

    it 'schedules a contribution for each trial' do
      freeze_time do
        expect(Contributions::ScheduleContributionForTrial)
          .to receive(:run)
          .with(subscription: trial1, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForTrial)
          .to receive(:run)
          .with(subscription: trial2, scheduled_at: Time.zone.now)
        expect(Contributions::ScheduleContributionForTrial)
          .to receive(:run)
          .with(subscription: trial3, scheduled_at: Time.zone.now)

        Contributions::ScheduleContributionsForPastDuePlans.run
      end
    end
  end
end
