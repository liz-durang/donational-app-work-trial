require 'rails_helper'

RSpec.describe Contributions::GetPlansDueSubscription do
  include ActiveSupport::Testing::TimeHelpers

  subject { Contributions::GetPlansDueSubscription.call }

  context 'when it is at least the 15th of the month' do
    around do |spec|
      travel_to(Time.new(2000, 6, 15, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there are no active monthly plans' do
      before do
        create(:subscription,
          frequency: 'monthly',
          start_at: Date.new(2000, 1, 1),
          last_scheduled_at: nil,
          deactivated_at: Date.new(2000, 1, 2)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active monthly plan that has had a contribution this month' do
      before do
        create(:subscription,
          frequency: 'monthly',
          start_at: Date.new(2000, 1, 1),
          last_scheduled_at: Date.new(2000, 6, 15)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active monthly plan that has not had a contribution this month' do
      let!(:monthly_plan_without_existing_contribution_this_month) {
        create(:subscription, frequency: 'monthly', start_at: Date.new(2000, 1, 1), last_scheduled_at: Date.new(2000, 5, 15))
      }

      it 'returns the active plan' do
        expect(subject).to eq [monthly_plan_without_existing_contribution_this_month]
      end
    end
  end

  context 'when it is before the 15th of the month' do
    around do |spec|
      travel_to(Time.new(2000, 6, 1, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there is an active monthly plan that has not had a contribution this month' do
      let!(:monthly_plan_without_existing_contribution_this_month) {
        create(:subscription, frequency: 'monthly', start_at: Date.new(2000, 1, 1), last_scheduled_at: Date.new(2000, 5, 15))
      }

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end
  end

  context 'when there are quarterly plans' do
    around do |spec|
      travel_to(Time.new(2000, 5, 15, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there are no active quarterly plans' do
      before do
        create(:subscription,
          frequency: 'quarterly',
          start_at: Date.new(2000, 1, 1),
          last_scheduled_at: nil,
          deactivated_at: Date.new(2000, 1, 2)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active quarterly plan that has had a contribution this quarter' do
      before do
        create(:subscription,
          frequency: 'quarterly',
          start_at: Date.new(2000, 1, 1),
          last_scheduled_at: Date.new(2000, 4, 1)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active quarterly plan that has not had a contribution this quarter' do
      let!(:quarterly_plan_without_existing_contribution_this_quarter) {
        create(:subscription,
          frequency: 'quarterly',
          start_at: Date.new(2000, 1, 1),
          last_scheduled_at: Date.new(2000, 1, 1)
        )
      }

      it 'returns the active plan' do
        expect(subject).to eq [quarterly_plan_without_existing_contribution_this_quarter]
      end
    end
  end

  context 'when there are annually plans' do
    around do |spec|
      travel_to(Time.new(2000, 5, 15, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there are no active annually plans' do
      before do
        create(:subscription,
          frequency: 'annually',
          start_at: Date.new(1998, 1, 1),
          last_scheduled_at: Date.new(1999, 1, 1),
          deactivated_at: Date.new(1999, 3, 1)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active annually plan that has had a contribution within the last year' do
      before do
        create(:subscription,
          frequency: 'annually',
          start_at: Date.new(1998, 10, 21),
          last_scheduled_at: Date.new(1999, 10, 21)
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active annually plan that has not had a contribution this year' do
      let!(:annual_plan_without_existing_contribution_this_year) {
        create(:subscription,
          frequency: 'annually',
          start_at: Date.new(1998, 5, 15),
          last_scheduled_at: Date.new(1999, 5, 15)
        )
      }

      it 'returns the active plan' do
        expect(subject).to eq [annual_plan_without_existing_contribution_this_year]
      end
    end
  end
end
