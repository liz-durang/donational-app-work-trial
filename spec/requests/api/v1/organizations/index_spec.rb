require 'rails_helper'

describe 'GET api/v1/organizations', type: :request do
  let!(:searchable_organization_1) { create(:searchable_organization, :reindex, name: 'Charity') }
  let!(:searchable_organization_2) { create(:searchable_organization, :reindex, name: 'Some Organization') }
  let(:name)                      { 'Some Org' }

  describe 'GET index', search: true do
    it 'returns a successful response' do
      get api_v1_organizations_path(name: name), as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns the organizations' do
      SearchableOrganization.search_index.refresh
      sleep 5

      get api_v1_organizations_path(name: name), as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:organizations][0][:ein]).to eq(searchable_organization_2.formatted_ein)
      expect(json[:organizations][0][:name]).to eq(searchable_organization_2.formatted_name)
      expect(json[:organizations][0][:state]).to eq(searchable_organization_2.state)
    end

    context 'when no search query is provided' do
      let(:name) { nil }

      it 'does not return the organizations' do
        get api_v1_organizations_path(name: name), as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:organizations]).to eq([])
      end
    end
  end
end
