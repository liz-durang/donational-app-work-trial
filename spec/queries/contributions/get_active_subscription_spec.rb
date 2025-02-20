require 'rails_helper'

RSpec.describe Contributions::GetActiveSubscription, type: :query do
  let(:donor) { create(:donor) }
  let!(:subscription1) { create(:subscription, donor: donor, created_at: 1.day.ago) }
  let!(:subscription2) { create(:subscription, donor: donor, created_at: 2.days.ago) }
  let!(:inactive_subscription) { create(:subscription, donor: donor, deactivated_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns the most recent active subscription for the donor' do
      expect(subject).to eq(subscription1)
    end

    it 'does not return inactive subscriptions' do
      expect(subject).not_to eq(inactive_subscription)
    end
  end
end
