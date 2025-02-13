# == Schema Information
#
# Table name: selected_portfolios
#
#  id             :bigint           not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe SelectedPortfolio, type: :model do
  describe 'associations' do
    it { should belong_to(:donor) }
    it { should belong_to(:portfolio) }
  end

  describe 'methods' do
    describe '#active?' do
      let(:active_selected_portfolio) { build(:selected_portfolio, deactivated_at: nil) }
      let(:inactive_selected_portfolio) { build(:selected_portfolio, deactivated_at: Time.current) }

      it 'returns true if deactivated_at is nil' do
        expect(active_selected_portfolio.active?).to be true
      end

      it 'returns false if deactivated_at is not nil' do
        expect(inactive_selected_portfolio.active?).to be false
      end
    end
  end
end
