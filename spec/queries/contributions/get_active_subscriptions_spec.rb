require 'rails_helper'

RSpec.describe Contributions::GetActiveSubscriptions, type: :query do
  let(:donor) { create(:donor) }
  let!(:active_subscription1) { create(:subscription, donor: donor, deactivated_at: nil) }
  let!(:active_subscription2) { create(:subscription, donor: donor, deactivated_at: nil) }
  let!(:inactive_subscription) { create(:subscription, donor: donor, deactivated_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns all active subscriptions for the donor' do
      expect(subject).to match_array([active_subscription1, active_subscription2])
    end

    it 'does not return inactive subscriptions' do
      expect(subject).not_to include(inactive_subscription)
    end
  end
end
