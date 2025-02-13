require 'rails_helper'

RSpec.describe Partners::GetManagedPortfolioById, type: :query do
  let!(:managed_portfolio) { create(:managed_portfolio) }

  describe '#call' do
    subject { described_class.new.call(id: portfolio_id) }

    context 'when the id is present' do
      let(:portfolio_id) { managed_portfolio.id }

      it 'returns the managed portfolio with the given id' do
        expect(subject).to eq(managed_portfolio)
      end
    end

    context 'when the id is blank' do
      let(:portfolio_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the managed portfolio with the given id does not exist' do
      let(:portfolio_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
