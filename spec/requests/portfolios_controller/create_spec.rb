require 'rails_helper'

RSpec.describe 'POST /portfolio', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:allocations) { create_list(:allocation, 3, portfolio: portfolio) }
  let(:allocation_params) do
    allocations.each_with_object({}).with_index do |(allocation, hash), index|
      hash[index.to_s] = { organization_id: allocation.organization_ein, percentage: allocation.percentage }
    end
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
  end

  context 'when the portfolio is created successfully' do
    before do
      allow(Portfolios::CreateOrReplacePortfolio).to receive(:run).and_return(successful_outcome)
      allow(Portfolios::UpdateAllocations).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the portfolio path' do
      post portfolio_path, params: { allocations: allocation_params }
      expect(response).to redirect_to(portfolio_path)
    end
  end

  context 'when the portfolio creation fails' do
    before do
      allow(Portfolios::UpdateAllocations).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the new portfolio path' do
      post portfolio_path, params: { allocations: allocation_params }
      expect(response).to redirect_to(new_portfolio_path)
    end

    it 'sets a flash error message' do
      post portfolio_path, params: { allocations: allocation_params }
      expect(flash[:alert]).to eq('Error message')
    end
  end
end
