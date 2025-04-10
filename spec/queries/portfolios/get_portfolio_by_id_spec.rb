require 'rails_helper'

RSpec.describe Portfolios::GetPortfolioById, type: :query do
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call(id: id) }

    context 'when the id is present' do
      let(:portfolio) { create(:portfolio) }
      let(:id) { portfolio.id}

      it 'returns the portfolio with the given id' do
        expect(subject).to eq(portfolio)
      end
    end

    context 'when the id is not present' do
      let(:id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the id does not exist' do
      let(:id) { 999 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the id is blank' do
      let(:id) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when an error occurs' do
      let(:id) { 1 }

      before do
        allow(service).to receive(:call).and_raise(StandardError.new('error'))
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError, 'error')
      end
    end
  end
end
