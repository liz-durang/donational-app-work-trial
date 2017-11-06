require 'rails_helper'

RSpec.describe Portfolios::GetActivePortfolio do
  let(:donor) { create(:donor) }

  subject { Portfolios::GetActivePortfolio.call(donor: donor) }

  context 'when there are no active portfolios' do
    before do
      allow_any_instance_of(Portfolios::GetActivePortfolios)
        .to receive(:call)
        .with(donor: donor)
        .and_return(Portfolio.none)
    end

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'when there are an existing active portfolios' do
    before do
      allow_any_instance_of(Portfolios::GetActivePortfolios)
        .to receive(:call)
        .with(donor: donor)
        .and_return([portfolio_1, portfolio_2])
    end

    let(:portfolio_1) { instance_double(Portfolio) }
    let(:portfolio_2) { instance_double(Portfolio) }

    it 'returns the first active portfolio' do
      expect(subject).to eq portfolio_1
    end
  end
end
