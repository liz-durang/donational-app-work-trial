require 'rails_helper'

RSpec.describe Portfolios::UpdateManagedPortfolio do
  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }
  let(:portfolio) { create(:portfolio) }
  let(:managed_portfolio) { create(:managed_portfolio, portfolio:) }

  before do
    Portfolios::CreateManagedPortfolio.run(
      partner:,
      donor:,
      title: 'Title',
      description: 'Description'
    )
  end

  context 'when there is an existing active portfolio' do
    let!(:existing_allocation) { create(:allocation, organization:, portfolio:, percentage: 100) }
    let!(:new_organization) { create(:organization) }

    it 'deactivates the previous allocations' do
      command = Portfolios::UpdateManagedPortfolio.run(
        managed_portfolio:,
        donor:,
        title: 'New Title',
        description: 'New Description',
        featured: true,
        organizations: [
          "#{organization.name}, #{organization.ein}",
          "#{another_organization.name}, #{another_organization.ein}",
          "#{new_organization.name}, #{new_organization.ein}"
        ]
      )
      managed_portfolio.reload
      expect(existing_allocation.reload.deactivated_at).to be_present
      expect(managed_portfolio.name).to eq 'New Title'
      expect(managed_portfolio.featured).to be true
      expect(managed_portfolio.description).to eq 'New Description'
      expect(managed_portfolio.portfolio.allocations.where(deactivated_at: nil).count).to eq 3
    end
  end
end
