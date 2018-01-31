require 'rails_helper'

RSpec.describe Portfolios::CreateOrReplacePortfolio do
  subject do
    Portfolios::CreateOrReplacePortfolio.run(portfolio_params)
  end

  let(:portfolio_params) do
    {
      donor: donor,
      contribution_amount_cents: 8000,
      contribution_frequency: :monthly
    }
  end
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  context 'when there are no existing portfolios for the donor' do
    it 'creates a new active portfolio' do
      expect { subject }.to change { Portfolio.count }.from(0).to(1)

      portfolio = Portfolios::GetActivePortfolio.call(donor: donor)

      expect(portfolio).to be_active
      expect(portfolio.contribution_amount_cents).to eq 8000
      expect(portfolio.contribution_frequency).to eq 'monthly'
    end
  end

  context 'when there is an existing active portfolio' do
    let!(:existing_portfolio) do
      create(:portfolio, donor: donor, deactivated_at: nil)
    end

    let!(:portfolio_for_other_donor) do
      create(:portfolio, donor: other_donor, deactivated_at: nil)
    end

    it 'deactivates the previous portfolios for the donor' do
      expect { subject }.not_to(change { portfolio_for_other_donor.active? })

      expect(existing_portfolio.reload).not_to be_active
    end

    it 'creates a new active portfolio for the donor' do
      expect { subject }.to change { Portfolio.count }.from(2).to(3)

      portfolio = Portfolios::GetActivePortfolio.call(donor: donor)
      expect(portfolio).to be_active
      expect(portfolio.donor).to eq donor
      expect(portfolio.contribution_amount_cents).to eq 8000
    end
  end
end
