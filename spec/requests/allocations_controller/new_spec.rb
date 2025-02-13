require 'rails_helper'

RSpec.describe 'GET /allocations/new', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:organizations) { create_list(:organization, 3) }

  before do
    login_as(donor)
    allow_any_instance_of(AllocationsController).to receive(:active_portfolio).and_return(portfolio)
    allow_any_instance_of(AllocationsController).to receive(:organizations_available_to_add_to_portfolio).and_return(organizations)
  end

  it 'renders the new template with the correct data' do
    get '/allocations/new'
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:new)

    expect(response.body).to include('Add a charity to your portfolio')
    expect(response.body).to include('Search for a charity')
    expect(response.body).to include('Choose one of our vetted high-impact charities')
    expect(response.body).to include('Donational recommends these high impact charities. Add one to your portfolio!')

    organizations.each do |organization|
      expect(response.body).to include(organization.name)
      expect(response.body).to include(organization.ein)
    end
  end
end
