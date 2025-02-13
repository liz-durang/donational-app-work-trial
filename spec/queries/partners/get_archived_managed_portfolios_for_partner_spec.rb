require 'rails_helper'

RSpec.describe Partners::GetArchivedManagedPortfoliosForPartner, type: :query do
  let(:partner) { create(:partner) }
  let!(:archived_portfolio1) { create(:managed_portfolio, partner:, hidden_at: 1.day.ago, display_order: 2) }
  let!(:archived_portfolio2) { create(:managed_portfolio, partner:, hidden_at: 2.days.ago, display_order: 1) }
  let!(:active_portfolio) { create(:managed_portfolio, partner:, hidden_at: nil) }
  let!(:other_partner_portfolio) { create(:managed_portfolio, hidden_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(partner: partner) }

    context 'when the partner is present' do
      it 'returns archived managed portfolios for the given partner ordered by display order' do
        expect(subject).to eq([archived_portfolio2, archived_portfolio1])
      end

      it 'does not return active portfolios' do
        expect(subject).not_to include(active_portfolio)
      end

      it 'does not return portfolios for other partners' do
        expect(subject).not_to include(other_partner_portfolio)
      end
    end
  end
end
