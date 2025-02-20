require 'rails_helper'

RSpec.describe Contributions::GetSubscriptionsByFrequency, type: :query do
  let(:frequency) { 'monthly' }
  let!(:active_subscription1) { create(:subscription, frequency: frequency, deactivated_at: nil, start_at: 1.day.ago) }
  let!(:active_subscription2) { create(:subscription, frequency: frequency, deactivated_at: nil, start_at: 2.days.ago) }
  let!(:inactive_subscription) { create(:subscription, frequency: frequency, deactivated_at: 1.day.ago, start_at: 1.day.ago) }
  let!(:future_subscription) { create(:subscription, frequency: frequency, deactivated_at: nil, start_at: 1.day.from_now) }
  let!(:different_frequency_subscription) { create(:subscription, frequency: 'annually', deactivated_at: nil, start_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(frequency: frequency) }

    it 'returns active subscriptions with the given frequency' do
      expect(subject).to match_array([active_subscription1, active_subscription2])
    end

    it 'does not return inactive subscriptions' do
      expect(subject).not_to include(inactive_subscription)
    end

    it 'does not return future subscriptions' do
      expect(subject).not_to include(future_subscription)
    end

    it 'does not return subscriptions with a different frequency' do
      expect(subject).not_to include(different_frequency_subscription)
    end
  end
end
