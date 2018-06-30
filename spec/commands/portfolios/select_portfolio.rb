require 'rails_helper'

RSpec.describe Portfolios::SelectPortfolio do
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  context 'when there are no existing portfolios for the donor' do
    it 'creates a new active portfolio' do
      expect { Portfolios::SelectPortfolio.run(donor: donor) }
        .to change { SelectedPortfolio.count }.from(0).to(1)

      portfolio = Portfolios::GetActivePortfolio.call(donor: donor)

      expect(portfolio).to be_active
    end
  end

  context 'when there is an existing active portfolio' do
    let!(:existing_portfolio) { create(:portfolio) }
    let!(:existing_selection) do
      create(:selected_portfolio, donor: donor, portfolio: existing_portfolio, deactivated_at: nil)
    end

    let!(:portfolio_for_other_donor) { create(:portfolio) }
    let!(:selection_for_other_donor) do
      create(:selected_portfolio, donor: other_donor, portfolio: portfolio_for_other_donor, deactivated_at: nil)
    end

    let(:new_portfolio) { create(:portfolio) }

    it 'deactivates the previous portfolios for the donor' do
      Portfolios::SelectPortfolio.run(donor: donor, portfolio: new_portfolio)

      expect(selection_for_other_donor.reload).to be_active
      expect(existing_selection.reload).not_to be_active
    end

    it 'activates the new portfolio for the donor' do
      Portfolios::SelectPortfolio.run(donor: donor, portfolio: new_portfolio)

      portfolio = Portfolios::GetActivePortfolio.call(donor: donor)
      expect(portfolio).to eq new_portfolio
    end
  end
end
