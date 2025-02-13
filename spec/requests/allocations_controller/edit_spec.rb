require 'rails_helper'

RSpec.describe 'GET /allocations/edit', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:allocations) { create_list(:allocation, 3, portfolio: portfolio) }
  let(:partner) { create(:partner) }
  let(:managed_portfolio) { create(:managed_portfolio, portfolio: portfolio, partner: partner) }

  before do
    login_as(donor)
    allow_any_instance_of(AllocationsController).to receive(:active_portfolio).and_return(portfolio)
    allow(Portfolios::GetActiveAllocations).to receive(:call).and_return(allocations)
    allow(Portfolios::GetPortfolioManager).to receive(:call).and_return(partner)
  end

  it 'renders the edit template with the correct content' do
    get '/allocations/edit'
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:edit)

    # Check for specific content in the response body
    expect(response.body).to include('Your personal charity portfolio')
    allocations.each do |allocation|
      expect(response.body).to include(allocation.organization_ein)
      expect(response.body).to include(allocation.percentage.to_s)
    end
    expect(response.body).to include(partner.name) if partner
  end
end
