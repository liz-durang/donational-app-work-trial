require 'rails_helper'

RSpec.describe Contributions::GetActiveTrial, type: :query do
  let(:donor) { create(:donor) }
  let!(:active_trial) { create(:subscription, donor: donor, trial_deactivated_at: nil, trial_amount_cents: 1000, start_at: 1.day.from_now) }
  let!(:inactive_trial) { create(:subscription, donor: donor, trial_deactivated_at: 1.day.ago, trial_amount_cents: 1000, start_at: 1.day.from_now) }
  let!(:past_trial) { create(:subscription, donor: donor, trial_deactivated_at: nil, trial_amount_cents: 1000, start_at: 1.day.ago) }
  let!(:zero_amount_trial) { create(:subscription, donor: donor, trial_deactivated_at: nil, trial_amount_cents: 0, start_at: 1.day.from_now) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns the most recent active trial for the donor' do
      expect(subject).to eq(active_trial)
    end

    it 'does not return inactive trials' do
      expect(subject).not_to eq(inactive_trial)
    end

    it 'does not return past trials' do
      expect(subject).not_to eq(past_trial)
    end

    it 'does not return trials with zero amount' do
      expect(subject).not_to eq(zero_amount_trial)
    end
  end
end
