require 'rails_helper'

RSpec.describe Contributions::GetLastDeactivatedSubscription, type: :query do
  let(:donor) { create(:donor) }
  let!(:active_subscription) { create(:subscription, donor: donor, deactivated_at: nil) }
  let!(:deactivated_subscription1) { create(:subscription, donor: donor, deactivated_at: 2.days.ago) }
  let!(:deactivated_subscription2) { create(:subscription, donor: donor, deactivated_at: 1.day.ago) }
  let!(:other_deactivated_subscription) { create(:subscription, deactivated_at: 3.days.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns the last deactivated subscription for the given donor' do
      expect(subject).to eq(deactivated_subscription2)
    end

    it 'does not return active subscriptions' do
      expect(subject).not_to eq(active_subscription)
    end

    it 'does not return deactivated subscriptions for other donors' do
      expect(subject).not_to eq(other_deactivated_subscription)
    end
  end
end
