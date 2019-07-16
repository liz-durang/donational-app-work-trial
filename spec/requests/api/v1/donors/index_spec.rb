require 'rails_helper'

describe 'GET api/v1/donors', type: :request do
  let(:partner)              { create(:partner) }
  let(:affiliated_donor)     { create(:donor, email: 'donor@example.com') }
  let(:unaffiliated_donor)   { create(:donor, email: 'unaffiliated_donor@example.com') }
  let!(:partner_affiliation) { create(:partner_affiliation, donor_id: affiliated_donor.id, partner_id: partner.id) }
  let(:email)                { 'donor@example.com' }

  describe 'GET index' do

    it 'returns a successful response' do
      get api_v1_donors_path(email: email), headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns the donor' do
      get api_v1_donors_path(email: email), headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:donors][0][:id]).to eq(affiliated_donor.id)
      expect(json[:donors][0][:first_name]).to eq(affiliated_donor.first_name)
      expect(json[:donors][0][:last_name]).to eq(affiliated_donor.last_name)
      expect(json[:donors][0][:email]).to eq(affiliated_donor.email)
    end

    context 'when no search query is provided' do
      let(:email) { nil }

      it 'does not return the donors' do
        get api_v1_donors_path(email: email), headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:donors]).to eq([])
      end
    end
  end
end
