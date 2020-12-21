require 'rails_helper'

RSpec.describe Portfolios::CreateManagedPortfolio do
  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }

  context 'when there are no existing portfolios for the partner' do
    it 'creates a new active portfolio' do
      expect {
        Portfolios::CreateManagedPortfolio.run(
          partner: partner,
          donor: donor,
          title: "Title",
          description: "Description"
        )
      }.to change { ManagedPortfolio.count }.from(0).to(1)

      managed_portfolio = partner.managed_portfolios.last
      expect(managed_portfolio.portfolio).to be_active
    end
  end
end
