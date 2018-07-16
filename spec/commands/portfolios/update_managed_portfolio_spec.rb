require 'rails_helper'

RSpec.describe Portfolios::UpdateManagedPortfolio do
  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }

  before do
    Portfolios::CreateManagedPortfolio.run(
      partner: partner,
      donor: donor,
      title: "Title",
      description: "Description",
      charities: ["#{organization.name}, #{organization.ein}", "#{another_organization.name}, #{another_organization.ein}"]
    )
  end

  context 'when there is an existing active portfolio' do
    let!(:new_organization) { create(:organization) }

    it 'deactivates the previous portfolios and creates a new one' do
      managed_portfolio = partner.managed_portfolios.last
      portfolio = managed_portfolio.portfolio

      command = Portfolios::UpdateManagedPortfolio.run(
        managed_portfolio: managed_portfolio,
        donor: donor,
        title: "New Title",
        description: "New Description",
        charities: ["#{organization.name}, #{organization.ein}", "#{new_organization.name}, #{new_organization.ein}"]
      )

      expect(portfolio.reload).not_to be_active
      expect(managed_portfolio.reload.name).to eq "New Title"
      expect(managed_portfolio.reload.description).to eq "New Description"
      expect(managed_portfolio.reload.portfolio.allocations.last.organization).to eq new_organization
    end
  end
end
