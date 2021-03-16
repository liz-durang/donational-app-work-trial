require 'rails_helper'

RSpec.describe Contributions::GetTrialsDueForFirstContribution do
  include ActiveSupport::Testing::TimeHelpers

  subject { Contributions::GetTrialsDueForFirstContribution.call }

  context 'when the trials all have at least one contribution' do
    before do
      create(:subscription, trial_amount_cents: 500, trial_start_at: 1.week.ago, trial_last_scheduled_at: 1.week.ago, start_at: 2.years.from_now)
      create(:subscription, trial_amount_cents: 500, trial_start_at: Time.zone.now, trial_last_scheduled_at: Time.zone.now, start_at: 2.years.from_now)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are unprocessed trials with future start dates' do
    before do
      create(:subscription, trial_amount_cents: 500, trial_start_at: 1.week.from_now, trial_last_scheduled_at: nil, start_at: 2.years.from_now)
      create(:subscription, trial_amount_cents: 500, trial_start_at: 1.month.from_now, trial_last_scheduled_at: nil, start_at: 2.years.from_now)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are deactivated unprocessed trials with past start dates' do
    let!(:deactivated_past_due_trial) {
      create(:subscription,
             trial_start_at: 1.day.ago,
             trial_amount_cents: 500,
             trial_last_scheduled_at: nil,
             trial_deactivated_at: 1.day.ago + 1.second,
             start_at: 2.years.from_now)
    }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are active unprocessed trials with past start dates' do
    around do |spec|
      travel_to(Date.new(Date.today.year,Date.today.month,20)) do
        spec.run
      end
    end

    let!(:recently_created_trial) {
      create(:subscription,
             trial_amount_cents: 500,
             trial_start_at: Time.zone.now,
             trial_last_scheduled_at: nil,
             start_at: 2.years.from_now)
    }
    let!(:older_trial_that_still_has_no_contributons_scheduled) {
      create(:subscription,
             trial_amount_cents: 500,
             trial_start_at: 1.week.ago,
             trial_last_scheduled_at: nil,
             start_at: 2.years.from_now)
    }
    let!(:older_trial_that_has_contributions) {
      create(:subscription,
             trial_amount_cents: 500,
             trial_start_at: 1.day.ago,
             trial_last_scheduled_at: 1.day.ago,
             start_at: 2.years.from_now)
    }

    it 'returns the unprocessed trials with past start dates' do
      expect(subject.size).to eq 2
      expect(subject).to include(recently_created_trial)
      expect(subject).to include(older_trial_that_still_has_no_contributons_scheduled)
    end
  end
end
