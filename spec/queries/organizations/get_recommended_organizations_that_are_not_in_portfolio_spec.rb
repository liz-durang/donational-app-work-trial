require 'rails_helper'

RSpec.describe Organizations::GetRecommendedOrganizationsThatAreNotInPortfolio, type: :query do
  let(:portfolio) { create(:portfolio) }
  let(:organization1) { create(:organization, ein: '123456789') }
  let(:organization2) { create(:organization, ein: '987654321') }
  let(:organization_in_portfolio) { create(:organization, ein: '111111111') }

  before do
    allow(Organizations::GetRecommendedOrganizations).to receive_message_chain(:new, :call).and_return(Organization.where(ein: [organization1, organization2, organization_in_portfolio].pluck(:ein)))
    allow(Portfolios::GetActiveAllocations).to receive(:call).with(portfolio: portfolio).and_return([double(organization_ein: '111111111')])
  end

  describe '#call' do
    subject { described_class.new.call(portfolio: portfolio) }

    it 'returns recommended organizations that are not in the portfolio' do
      expect(subject).to match_array([organization1, organization2])
    end

    it 'does not return organizations that are in the portfolio' do
      expect(subject).not_to include(organization_in_portfolio)
    end
  end
end
