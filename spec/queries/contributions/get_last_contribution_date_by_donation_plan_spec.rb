require 'rails_helper'

RSpec.describe Contributions::GetLastContributionDateByDonationPlan, type: :query do
  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio) }
  let(:subscription) { create(:subscription, donor: donor, portfolio: portfolio) }
  let!(:contribution1) { create(:contribution, donor: donor, portfolio: portfolio, scheduled_at: 2.days.ago) }
  let!(:contribution2) { create(:contribution, donor: donor, portfolio: portfolio, scheduled_at: 1.day.ago) }
  let!(:other_contribution) { create(:contribution, scheduled_at: 3.days.ago) }

  describe '#call' do
    subject { described_class.new.call(subscription: subscription) }

    it 'returns the last contribution date for the given subscription' do
      expect(subject).to eq(contribution2.scheduled_at.to_date)
    end

    it 'does not return contributions for other subscriptions' do
      expect(subject).not_to eq(other_contribution.scheduled_at.to_date)
    end
  end
end
