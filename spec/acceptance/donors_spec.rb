require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Donors' do
  let(:donor)                { Donor.find_by(first_name: 'Donny') }
  let(:entity)               { Donor.find_by(entity_name: 'Company') }
  let(:partner)              { create(:partner) }
  let(:api_key)              { partner.api_key }
  let(:affiliated_donor)     { create(:donor, email: 'donor@example.com') }
  let(:unaffiliated_donor)   { create(:donor, email: 'unaffiliated_donor@example.com') }
  let!(:partner_affiliation) { create(:partner_affiliation, donor_id: affiliated_donor.id, partner_id: partner.id) }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :api_key

  # POST api/v1/donors/
  post '/api/v1/donors' do
    # Request parameters
    parameter :first_name, 'Donor first name', type: :string, required: false
    parameter :last_name, 'Donor last name', type: :string, required: false
    parameter :entity_name, 'Entity name', type: :string, required: false
    parameter :email, 'Donor email', type: :string, required: true

    explanation 'Donors must be created with either an entity_name or a first_name and last_name.'

    context '200' do
      context 'Person' do
        let(:params) do
          {
            donor: {
              first_name: 'Donny',
              last_name: 'Donator',
              email: 'user@example.com'
            }
          }.to_json
        end

        example 'Succesful request: Create a donor' do
          do_request

          expect(status).to eq(200)
          response = JSON.parse(response_body)
          expect(response['donor']['first_name']).to eq(donor.first_name)
          expect(response['donor']['last_name']).to eq(donor.last_name)
          expect(response['donor']['email']).to eq(donor.email)
        end
      end

      context 'Entity' do
        let(:params) do
          {
            donor: {
              entity_name: 'Company',
              email: 'company@example.com'
            }
          }.to_json
        end

        example 'Succesful request: Create a donor' do
          do_request

          expect(status).to eq(200)
          response = JSON.parse(response_body)
          expect(response['donor']['entity_name']).to eq(entity.entity_name)
          expect(response['donor']['email']).to eq(entity.email)
        end
      end
    end

    context '422' do
      context 'Email' do
        let(:params) do
          {
            donor: {
              email: ''
            }
          }.to_json
        end

        example 'Invalid request: Create a donor without email' do
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq("Email can't be blank")
        end
      end

      context 'Name' do
        let(:params) do
          {
            donor: {
              email: 'user@example.com'
            }
          }.to_json
        end

        example 'Invalid request: Create a donor without name' do
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq('Either entity_name or first_name and last_name should be present')
        end
      end
    end
  end

  # Get api/v1/donors/:id
  get '/api/v1/donors/:id' do
    # Request parameters
    parameter :id, type: :string, required: true

    let(:id)  { affiliated_donor.id }

    context '200' do
      example 'Successful request: Search donor by id' do
        do_request

        expect(status).to eq(200)

        response = JSON.parse(response_body)
        expect(response['donor']['id']).to eq(affiliated_donor.id)
        expect(response['donor']['first_name']).to eq(affiliated_donor.first_name)
        expect(response['donor']['last_name']).to eq(affiliated_donor.last_name)
        expect(response['donor']['email']).to eq(affiliated_donor.email)
      end
    end

    context '404' do
      parameter :id, type: :string, required: true

      let(:id)  { 'invalid_id' }

      example 'Invalid request: Search donor by id' do
        do_request

        expect(status).to eq(404)
        response = JSON.parse(response_body)
        expect(response['error']).to eq("Could not find a donor with id #{id}")
      end
    end

    context '404' do
      parameter :id, type: :string, required: true

      let(:id)  { unaffiliated_donor.id }

      example 'Invalid request: Search donor by id' do
        do_request

        expect(status).to eq(404)
        response = JSON.parse(response_body)
        expect(response['error']).to eq("Could not find a donor with id #{id}")
      end
    end
  end

  # Get api/v1/donors/
  get '/api/v1/donors' do
    # Request parameters
    parameter :email, type: :string, required: true

    let(:email)  { affiliated_donor.email }

    context '200' do

      example 'Successful request: Search donor by email' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['donors'][0]['id']).to eq(affiliated_donor.id)
        expect(response['donors'][0]['first_name']).to eq(affiliated_donor.first_name)
        expect(response['donors'][0]['last_name']).to eq(affiliated_donor.last_name)
        expect(response['donors'][0]['email']).to eq(affiliated_donor.email)
      end
    end
  end
end
