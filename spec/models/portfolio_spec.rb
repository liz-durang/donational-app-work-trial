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
  describe '#active?' do
    context 'when it has a deactivated_at timestamp' do
      it 'is false' do
        portfolio = Portfolio.new(deactivated_at: 1.day.ago)
        expect(portfolio.active?).to be false
      end
    end

    context 'when it does not have a deactivated_at timestamp' do
      it 'is true' do
        portfolio = Portfolio.new(deactivated_at: nil)
        expect(portfolio.active?).to be true
      end
    end
  end
end
