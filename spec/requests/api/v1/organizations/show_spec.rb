require 'rails_helper'

describe 'GET api/v1/organizations', type: :request do
  let!(:searchable_organizations) { create_list(:searchable_organization, 2) }
  let(:partner)                   { create(:partner) }
  let(:ein)                       { searchable_organizations[0].ein }

  describe 'GET show' do

    it 'returns a successful response' do
      get api_v1_organization_path(id: ein), headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns the organization' do
      get api_v1_organization_path(id: ein), headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:organization][:ein]).to eq(searchable_organizations[0].formatted_ein)
      expect(json[:organization][:name]).to eq(searchable_organizations[0].formatted_name)
      expect(json[:organization][:state]).to eq(searchable_organizations[0].state)
    end

    context 'when a non existent ein is provided' do
      let(:ein) { 'invalid_ein' }

      it 'does not return a successful response' do
        get api_v1_organization_path(id: ein), headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:error]).to eq("Could not find an organization with EIN #{ein}")
      end
    end
  end
end
