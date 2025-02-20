require 'rails_helper'

RSpec.describe Contributions::GetSubscriptionsWhichNeedReminder, type: :query do
  let(:today) { Date.today.beginning_of_day }
  let(:next_week) { today + 7.days }
  let!(:subscription1) { create(:subscription, deactivated_at: nil, last_reminded_at: nil, start_at: today + 1.day) }
  let!(:subscription2) { create(:subscription, deactivated_at: nil, last_reminded_at: nil, start_at: today + 2.days) }
  let!(:subscription_outside_range) { create(:subscription, deactivated_at: nil, last_reminded_at: nil, start_at: today + 8.days) }
  let!(:subscription_deactivated) { create(:subscription, deactivated_at: today, last_reminded_at: nil, start_at: today + 1.day) }
  let!(:subscription_reminded) { create(:subscription, deactivated_at: nil, last_reminded_at: today, start_at: today + 1.day) }

  describe '#call' do
    subject { described_class.new.call }

    it 'returns subscriptions which need a reminder' do
      expect(subject).to match_array([subscription1, subscription2])
    end

    it 'does not return subscriptions outside the reminder range' do
      expect(subject).not_to include(subscription_outside_range)
    end

    it 'does not return deactivated subscriptions' do
      expect(subject).not_to include(subscription_deactivated)
    end

    it 'does not return subscriptions which have already been reminded' do
      expect(subject).not_to include(subscription_reminded)
    end
  end
end
