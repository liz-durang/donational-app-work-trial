require 'rails_helper'

RSpec.describe 'PUT /allocations', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:allocations) { create_list(:allocation, 3, portfolio: portfolio) }
  let(:valid_params) do
    {
      allocations: Hash[allocations.map.with_index { |a,i| [i, { organization_ein: a.organization_ein, percentage: a.percentage }] }].deep_symbolize_keys
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(AllocationsController).to receive(:active_portfolio).and_return(portfolio)
  end

  context 'when the request is valid' do
    before do
      allow(Portfolios::UpdateAllocations).to receive(:run).and_return(successful_outcome)
    end

    it 'updates the allocations and redirects to the edit allocations path with a success message' do
      put '/allocations', params: valid_params
      expect(response).to redirect_to(edit_allocations_path)
      follow_redirect!
      expect(CGI.unescapeHTML(response.body)).to include('Allocations saved!')
    end
  end

  context 'when the request is invalid' do
    before do
      allow(Portfolios::UpdateAllocations).to receive(:run).and_return(failure_outcome)
    end

    it 'renders the edit template with an error message' do
      put '/allocations', params: valid_params
      expect(response).to render_template(:edit)
      expect(CGI.unescapeHTML(response.body)).to include('Error message')
    end
  end
end
