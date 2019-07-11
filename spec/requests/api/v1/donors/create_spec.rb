require 'rails_helper'

describe 'POST api/v1/donors/', type: :request do
  let(:donor)           { Donor.last }
  let(:partner)         { create(:partner) }
  let(:failed_response) { 422 }

  describe 'POST create' do
    let(:email)       { 'donny@donator.com' }
    let(:first_name)  { 'Donny' }
    let(:last_name)   { 'Donator' }

    let(:params) do
      {
        donor: {
          email:      email,
          first_name: first_name,
          last_name:  last_name
        }
      }
    end

    it 'returns a successful response' do
      post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'creates the donor' do
      expect {
        post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
      }.to change(Donor, :count).by(1)
    end

    it 'returns the donor' do
      post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:donor][:id]).to eq(donor.id)
      expect(json[:donor][:email]).to eq(donor.email)
      expect(json[:donor][:first_name]).to eq(donor.first_name)
      expect(json[:donor][:last_name]).to eq(donor.last_name)
    end

    context 'when the email is not correct' do
      let(:email) { '' }

      it 'does not create a donor' do
        expect {
          post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { Donor.count }
      end

      it 'does not return a successful response' do
        post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(failed_response)
      end
    end

    context 'when the first name is not correct' do
      let(:first_name) { '' }

      it 'does not create a donor' do
        expect {
          post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { Donor.count }
      end

      it 'does not return a successful response' do
        post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(failed_response)
      end
    end

    context 'when the last name is not correct' do
      let(:last_name) { '' }

      it 'does not create a donor' do
        expect {
          post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { Donor.count }
      end

      it 'does not return a successful response' do
        post api_v1_donors_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(failed_response)
      end
    end
  end
end
