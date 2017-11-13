require 'rails_helper'

RSpec.describe Allocations::GetActiveAllocations do
  let(:other_portfolio) { create(:portfolio) }
  let(:portfolio) { create(:portfolio) }

  subject { Allocations::GetActiveAllocations.call(portfolio: portfolio) }

  context 'when there are no allocations for the portfolio' do
    before { create(:allocation, portfolio: other_portfolio) }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context "when all of the portfolio's allocations have been deactivated" do
    before do
      create(:allocation, portfolio: portfolio, deactivated_at: 2.days.ago)
      create(:allocation, portfolio: portfolio, deactivated_at: 1.day.ago)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there is an existing active allocations' do
    before do
      create(:allocation, portfolio: portfolio, deactivated_at: 2.days.ago)
      create(:allocation, portfolio: portfolio, deactivated_at: 1.day.ago)
    end

    let!(:allocation) do
      create(:allocation, portfolio: portfolio, deactivated_at: nil)
    end

    it 'returns the active allocation' do
      expect(subject).to be_a ActiveRecord::Relation
      expect(subject).to eq [allocation]
    end
  end
end
