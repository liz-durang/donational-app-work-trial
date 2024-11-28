# == Schema Information
#
# Table name: managed_portfolios
#
#  id            :uuid             not null, primary key
#  partner_id    :uuid
#  portfolio_id  :uuid
#  name          :string
#  description   :text
#  hidden_at     :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  display_order :integer
#  featured      :boolean
#

require 'rails_helper'

RSpec.describe ManagedPortfolio, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:partner) }
    it { is_expected.to belong_to(:portfolio) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe 'delegations' do
    describe '#size' do
      let!(:allocation) { create(:allocation) }
      subject { create(:managed_portfolio, portfolio: allocation.portfolio) }

      it 'is delegated to portfolio' do
        expect(subject.size).to eq(1)
      end
    end
  end

  describe 'methods' do
    describe '#available_to_new_donors?' do
      context 'with hidden_at nil' do
        subject { build(:managed_portfolio, hidden_at: nil) }

        it 'returns true' do
          expect(subject.available_to_new_donors?).to eq(true)
        end
      end
    end

    describe '#archived?' do
      context 'with hidden_at present' do
        subject { build(:managed_portfolio, hidden_at: DateTime.current) }

        it 'returns true' do
          expect(subject.archived?).to eq(true)
        end
      end
    end
  end
end
