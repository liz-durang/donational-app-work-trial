require 'rails_helper'

RSpec.describe Portfolios::GetPortfolioName, type: :query do
  let(:service) { described_class.new }
  let(:portfolio) { create(:portfolio) }

  describe '#call' do
    subject { service.call(portfolio: portfolio) }

    context 'when the portfolio has a name' do
      let!(:managed_portfolio) { create(:managed_portfolio, portfolio: portfolio, name: 'Test Portfolio') }

      it 'returns the name of the portfolio' do
        expect(subject).to eq('Test Portfolio')
      end
    end

    context 'when the portfolio has no name' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the portfolio is nil' do
      let(:portfolio) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when an error occurs' do
      before do
        allow(service).to receive(:call).and_raise(StandardError.new('error'))
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError, 'error')
      end
    end
  end
end
