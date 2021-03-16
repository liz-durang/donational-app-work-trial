require 'rails_helper'

RSpec.describe Contributions::GetTrialsDueSubscription do
  include ActiveSupport::Testing::TimeHelpers

  subject { Contributions::GetTrialsDueSubscription.call }

  context 'when it is at least the 15th of the month' do
    around do |spec|
      travel_to(Time.new(2000, 6, 15, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there are no active trials' do
      before do
        create(:subscription,
          frequency: 'monthly',
          trial_amount_cents: 500,
          trial_start_at: Date.new(2000, 1, 1),
          trial_deactivated_at: Date.new(2000, 1, 2),
          last_scheduled_at: nil,
          start_at: 2.year.from_now
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active trial that has had a contribution this month' do
      before do
        create(:subscription,
          frequency: 'monthly',
          trial_amount_cents: 500,
          trial_start_at: Date.new(2000, 1, 1),
          trial_deactivated_at: Date.new(2000, 1, 2),
          last_scheduled_at: Date.new(2000, 6, 15),
          start_at: 2.year.from_now
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end

    context 'and there is an active trial that has not had a contribution this month' do
      let!(:trial_without_existing_contribution_this_month) do
        create(:subscription,
          frequency: 'monthly',
          trial_amount_cents: 500,
          trial_start_at: Date.new(2000, 1, 1),
          trial_last_scheduled_at: Date.new(2000, 5, 15),
          start_at: 2.year.from_now
        )
      end

      it 'returns the active trial' do
        expect(subject).to eq [trial_without_existing_contribution_this_month]
      end
    end
  end

  context 'when it is before the 15th of the month' do
    around do |spec|
      travel_to(Time.new(2000, 6, 1, 12, 0, 0)) do
        spec.run
      end
    end

    context 'and there is an active trial that has not had a contribution this month' do
      let!(:trial_without_existing_contribution_this_month) do
        create(:subscription,
          frequency: 'monthly',
          trial_amount_cents: 500,
          trial_start_at: Date.new(2000, 1, 1),
          last_scheduled_at: Date.new(2000, 5, 15),
          start_at: 2.year.from_now
        )
      end

      it 'returns an empty relation' do
        expect(subject).to be_empty
      end
    end
  end
end
