require 'rails_helper'

RSpec.describe 'GET /searchable_organizations', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:organizations) { create_list(:searchable_organization, 3) }

  before do
    login_as(donor)
    allow(SearchableOrganization).to receive(:search_for).and_return(organizations)
  end

  context 'when the request is from portfolios' do
    it 'returns a successful response' do
      get searchable_organizations_path, params: { name: 'test', from: 'portfolios' }
      expect(response).to have_http_status(:success)
    end

    it 'renders the managed_portfolio partial' do
      get searchable_organizations_path, params: { name: 'test', from: 'portfolios' }
      expect(response).to render_template(partial: '_managed_portfolio')
    end

    it 'assigns the correct organizations' do
      get searchable_organizations_path, params: { name: 'test', from: 'portfolios' }
      expect(assigns(:organizations)).to eq(organizations)
    end
  end

  context 'when the request is from allocations' do
    it 'returns a successful response' do
      get searchable_organizations_path, params: { name: 'test', from: 'allocations' }
      expect(response).to have_http_status(:success)
    end

    it 'renders the allocations partial' do
      get searchable_organizations_path, params: { name: 'test', from: 'allocations' }
      expect(response).to render_template(partial: '_allocations')
    end

    it 'assigns the correct organizations' do
      get searchable_organizations_path, params: { name: 'test', from: 'allocations' }
      expect(assigns(:organizations)).to eq(organizations)
    end
  end
end
