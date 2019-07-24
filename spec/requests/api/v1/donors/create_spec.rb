require 'rails_helper'

describe 'POST api/v1/donors/', type: :request do
  let(:donor)           { Donor.last }
  let(:partner)         { create(:partner) }
  let(:failed_response) { 422 }

  describe 'POST create' do
    let(:email)       { 'donny@donator.com' }
    let(:first_name)  { 'Donny' }
    let(:last_name)   { 'Donator' }
    let(:entity_name) { 'Company' }

    let(:donor_params) do
      {
        donor: {
          email: email,
          first_name: first_name,
          last_name: last_name
        }
      }
    end

    let(:entity_params) do
      {
        donor: {
          email: email,
          entity_name: entity_name
        }
      }
    end

    let(:invalid_params) do
      {
        donor: {
          email: email
        }
      }
    end

    context 'donor person' do
      it 'returns a successful response' do
        post api_v1_donors_path, params: donor_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates the donor' do
        expect {
          post api_v1_donors_path, params: donor_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(Donor, :count).by(1)
      end

      it 'returns the donor' do
        post api_v1_donors_path, params: donor_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:donor][:id]).to eq(donor.id)
        expect(json[:donor][:email]).to eq(donor.email)
        expect(json[:donor][:first_name]).to eq(donor.first_name)
        expect(json[:donor][:last_name]).to eq(donor.last_name)
        expect(json[:donor][:entity_name]).to be(nil)
      end
    end

    context 'donor entity' do
      it 'returns a successful response' do
        post api_v1_donors_path, params: entity_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates the donor' do
        expect {
          post api_v1_donors_path, params: entity_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(Donor, :count).by(1)
      end

      it 'returns the donor' do
        post api_v1_donors_path, params: entity_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:donor][:id]).to eq(donor.id)
        expect(json[:donor][:email]).to eq(donor.email)
        expect(json[:donor][:entity_name]).to eq(donor.entity_name)
        expect(json[:donor][:first_name]).to be(nil)
        expect(json[:donor][:last_name]).to be(nil)
      end
    end

    context 'when the email is not correct' do
      let(:email) { '' }

      it 'does not create a donor' do
        expect {
          post api_v1_donors_path, params: donor_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { Donor.count }
      end

      it 'does not return a successful response' do
        post api_v1_donors_path, params: donor_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response.status).to eq(failed_response)
      end
    end

    context 'when the first name, last name and entity name are not correct' do
      it 'does not create a donor' do
        expect {
          post api_v1_donors_path, params: invalid_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { Donor.count }
      end

      it 'does not return a successful response' do
        post api_v1_donors_path, params: invalid_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(response.status).to eq(failed_response)
        expect(json[:errors][0]).to eq('Either entity_name or first_name and last_name should be present')
      end
    end
  end
end
