require 'rails_helper'

describe 'GET api/v1/organizations', type: :request do
  let!(:searchable_organizations) { create_list(:searchable_organization, 2) }
  let(:partner)                   { create(:partner) }
  let(:name)                      { 'Charity' }

  describe 'GET index' do

    it 'returns a successful response' do
      get api_v1_organizations_path(name: name), headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns the organizations' do
      get api_v1_organizations_path(name: name), headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:organizations][0][:ein]).to eq(searchable_organizations[0].formatted_ein)
      expect(json[:organizations][0][:name]).to eq(searchable_organizations[0].formatted_name)
      expect(json[:organizations][0][:state]).to eq(searchable_organizations[0].state)
    end

    context 'when no search query is provided' do
      let(:name) { nil }

      it 'does not return the organizations' do
        get api_v1_organizations_path(name: name), headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:organizations]).to eq([])
      end
    end
  end
end
