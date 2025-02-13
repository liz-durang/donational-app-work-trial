require 'rails_helper'

RSpec.describe Partners::GetManagedPortfoliosForPartner, type: :query do
  let(:partner) { create(:partner) }
  let!(:managed_portfolio1) { create(:managed_portfolio, partner: partner, hidden_at: nil, display_order: 2) }
  let!(:managed_portfolio2) { create(:managed_portfolio, partner: partner, hidden_at: nil, display_order: 1) }
  let!(:hidden_portfolio) { create(:managed_portfolio, partner: partner, hidden_at: 1.day.ago) }
  let!(:other_partner_portfolio) { create(:managed_portfolio, hidden_at: nil) }

  describe '#call' do
    subject { described_class.new.call(partner: partner) }

    context 'when the partner is present' do
      it 'returns managed portfolios for the given partner ordered by display order' do
        expect(subject).to eq([managed_portfolio2, managed_portfolio1])
      end

      it 'does not return hidden portfolios' do
        expect(subject).not_to include(hidden_portfolio)
      end

      it 'does not return portfolios for other partners' do
        expect(subject).not_to include(other_partner_portfolio)
      end
    end

    context 'when the partner is blank' do
      subject { described_class.new.call(partner: nil) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
