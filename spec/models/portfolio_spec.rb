# == Schema Information
#
# Table name: portfolios
#
#  id             :uuid             not null, primary key
#  creator_id     :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe Portfolio, type: :model do
  describe 'associations' do
    it { should belong_to(:creator).class_name('Donor').optional }
    it { should have_many(:contributions) }
    it { should have_many(:allocations) }
    it { should have_many(:active_allocations).class_name('Allocation').conditions(deactivated_at: nil) }
    it { should have_many(:donations) }
    it { should have_one(:managed_portfolio) }
  end

  describe 'methods' do
    describe '#active?' do
      context 'when it has a deactivated_at timestamp' do
        it 'is false' do
          portfolio = Portfolio.new(deactivated_at: 1.day.ago)
          expect(portfolio.active?).to eq(false)
        end
      end

      context 'when it does not have a deactivated_at timestamp' do
        it 'is true' do
          portfolio = Portfolio.new(deactivated_at: nil)
          expect(portfolio.active?).to eq(true)
        end
      end
    end

    describe '#size' do
      let(:portfolio) { create(:portfolio) }
      let!(:active_allocation1) { create(:allocation, portfolio: portfolio, deactivated_at: nil) }
      let!(:active_allocation2) { create(:allocation, portfolio: portfolio, deactivated_at: nil) }
      let!(:inactive_allocation) { create(:allocation, portfolio: portfolio, deactivated_at: Time.current) }

      it 'returns the count of active allocations' do
        expect(portfolio.size).to eq(2)
      end
    end
  end
end
