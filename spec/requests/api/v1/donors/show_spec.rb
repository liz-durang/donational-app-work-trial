require 'rails_helper'

describe 'GET api/v1/donors/:id', type: :request do
  let(:partner)              { create(:partner) }
  let(:affiliated_donor)     { create(:donor) }
  let(:unaffiliated_donor)   { create(:donor) }
  let!(:partner_affiliation) { create(:partner_affiliation, donor_id: affiliated_donor.id, partner_id: partner.id) }

  describe 'GET index' do

    it 'returns a successful response' do
      get api_v1_donor_path(id: affiliated_donor.id), headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns the donor' do
      get api_v1_donor_path(id: affiliated_donor.id), headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:donor][:id]).to eq(affiliated_donor.id)
      expect(json[:donor][:first_name]).to eq(affiliated_donor.first_name)
      expect(json[:donor][:last_name]).to eq(affiliated_donor.last_name)
      expect(json[:donor][:email]).to eq(affiliated_donor.email)
    end

    context 'when non existent id is provided' do
      let(:id) { 'invalid_id' }

      it 'does not return the donor' do
        get api_v1_donor_path(id: id), headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(404)
      end
    end

    context 'when donor is not affiliated' do
      let(:id) { unaffiliated_donor.id }

      it 'does not return the donor' do
        get api_v1_donor_path(id: id), headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(404)
      end
    end
  end
end
