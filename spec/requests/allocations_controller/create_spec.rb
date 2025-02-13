require 'rails_helper'

RSpec.describe 'POST /allocations', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:organization) { create(:organization) }
  let(:valid_params) do
    {
      organization: {
        ein: organization.ein,
        name: organization.name
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(AllocationsController).to receive(:active_portfolio).and_return(portfolio)
    allow_any_instance_of(PortfoliosController).to receive(:active_portfolio).and_return(portfolio)
    allow(Organizations::GetOrganizationByEin).to receive(:call).and_return(organization)
  end

  context 'when the request is valid' do
    before do
      allow(Organizations::FindOrCreateDonorSuggestedCharity).to receive(:run).and_return(successful_outcome)
      allow(Portfolios::AddOrganizationAndRebalancePortfolio).to receive(:run).and_return(successful_outcome)
    end

    it 'adds the organization to the portfolio and redirects to the portfolio path with a success message' do
      post '/allocations', params: valid_params
      expect(response).to redirect_to(portfolio_path)
      follow_redirect!
      expect(response.body).to include("#{organization.name} has been added to your portfolio")
    end
  end

  context 'when the request is invalid' do
    before do
      allow(Organizations::FindOrCreateDonorSuggestedCharity).to receive(:run).and_return(failure_outcome)
      allow(Portfolios::AddOrganizationAndRebalancePortfolio).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the portfolio path with an error message' do
      post '/allocations', params: valid_params
      expect(response).to redirect_to(portfolio_path)
      follow_redirect!  
      expect(response.body).to include('Error message')
    end
  end
end
