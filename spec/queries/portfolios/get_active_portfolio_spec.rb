require 'rails_helper'

RSpec.describe Portfolios::GetActivePortfolio do
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  subject { Portfolios::GetActivePortfolio.call(donor: donor) }

  context 'when there are no selected portfolios for the donor' do
    before { create(:portfolio, creator: other_donor) }

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context "when all of the donor's selected portfolios are deactivated" do
    before do
      create(:selected_portfolio, donor: donor, portfolio: create(:portfolio), deactivated_at: 2.days.ago)
      create(:selected_portfolio, donor: donor, portfolio: create(:portfolio), deactivated_at: 1.day.ago)
    end

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'when there is an existing active portfolio' do
    let(:active_portfolio) { create(:portfolio, deactivated_at: nil) }

    before do
      create(:selected_portfolio, donor: donor, portfolio: active_portfolio, deactivated_at: nil)
      create(:selected_portfolio, donor: donor, portfolio: create(:portfolio), deactivated_at: 2.days.ago)
      create(:selected_portfolio, donor: donor, portfolio: create(:portfolio), deactivated_at: 1.day.ago)
    end

    it 'returns the active portfolio' do
      expect(subject).to eq active_portfolio
    end
  end
end
