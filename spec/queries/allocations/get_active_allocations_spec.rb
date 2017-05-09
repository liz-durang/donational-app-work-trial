require 'rails_helper'

RSpec.describe Allocations::GetActiveAllocations do
  let(:other_subscription) { create(:subscription) }
  let(:subscription) { create(:subscription) }

  subject { Allocations::GetActiveAllocations.call(subscription: subscription) }

  context 'when there are no allocations for the subscription' do
    before { create(:allocation, subscription: other_subscription) }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context "when all of the subscription's allocations have been deactivated" do
    before do
      create(:allocation, subscription: subscription, deactivated_at: 2.days.ago)
      create(:allocation, subscription: subscription, deactivated_at: 1.day.ago)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there is an existing active allocations' do
    before do
      create(:allocation, subscription: subscription, deactivated_at: 2.days.ago)
      create(:allocation, subscription: subscription, deactivated_at: 1.day.ago)
    end

    let!(:allocation) do
      create(:allocation, subscription: subscription, deactivated_at: nil)
    end

    it 'returns the active allocation' do
      expect(subject).to be_a ActiveRecord::Relation
      expect(subject).to eq [allocation]
    end
  end
end
