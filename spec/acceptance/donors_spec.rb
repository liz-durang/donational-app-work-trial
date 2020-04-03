require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Donors' do
  let(:donor)                { Donor.find_by(first_name: 'Donny') }
  let(:uk_donor)             { Donor.find_by(email: uk_donor_email) }
  let(:entity)               { Donor.find_by(entity_name: 'Company') }
  let(:partner)              { create(:partner) }
  let(:uk_partner)           { create(:partner, currency: 'gbp') }
  let(:partner_api_key)      { partner.api_key }
  let(:uk_partner_api_key)   { uk_partner.api_key }
  let(:affiliated_donor)     { create(:donor, email: 'donor@example.com') }
  let(:unaffiliated_donor)   { create(:donor, email: 'unaffiliated_donor@example.com') }
  let!(:partner_affiliation) { create(:partner_affiliation, donor_id: affiliated_donor.id, partner_id: partner.id) }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :partner_api_key

  # POST api/v1/donors/
  post '/api/v1/donors' do
    # Request parameters
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

      context 'UK Person' do
        header 'X-Api-Key', :uk_partner_api_key

        let(:uk_donor_email)                { 'uk_user@example.com' }
        let(:uk_donor_title)                { 'Mr.' }
        let(:uk_donor_first_name)           { 'John' }
        let(:uk_donor_last_name)            { 'UKDonor' }
        let(:uk_donor_entity_name)          { 'UKCompany' }
        let(:uk_donor_house_name_or_number) { '100' }
        let(:uk_donor_postcode)             { 'PO1 3AX' }
        let(:uk_gift_aid_accepted)          { '1' }

        let(:params) do
          {
            donor: {
              title: uk_donor_title,
              first_name: uk_donor_first_name,
              last_name: uk_donor_last_name,
              house_name_or_number: uk_donor_house_name_or_number,
              postcode: uk_donor_postcode,
              email: uk_donor_email,
              uk_gift_aid_accepted: uk_gift_aid_accepted
            }
          }.to_json
        end

        example 'Succesful request: Create a UK donor' do
          do_request

          expect(status).to eq(200)
          response = JSON.parse(response_body)

          expect(response['donor']['first_name']).to eq(uk_donor_first_name)
          expect(response['donor']['last_name']).to eq(uk_donor_last_name)
          expect(response['donor']['email']).to eq(uk_donor_email)
          expect(response['donor']['title']).to eq(uk_donor_title)
          expect(response['donor']['house_name_or_number']).to eq(uk_donor_house_name_or_number)
          expect(response['donor']['postcode']).to eq(uk_donor_postcode)
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

    context '400' do
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

          expect(status).to eq(400)
          response = JSON.parse(response_body)
          expect(response['errors']['email'][0]).to eq("Email can't be blank")
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

          expect(status).to eq(400)
          response = JSON.parse(response_body)
          expect(response['errors']['donor'][0]).to eq('Either entity_name or first_name and last_name should be present')
        end
      end

      context 'UK Person with gift aid and withot required data' do
        header 'X-Api-Key', :uk_partner_api_key

        let(:uk_donor_email)                { 'uk_user@example.com' }
        let(:uk_donor_first_name)           { 'John' }
        let(:uk_donor_last_name)            { 'UKDonor' }
        let(:uk_gift_aid_accepted)          { '1' }

        let(:params) do
          {
            donor: {
              first_name: uk_donor_first_name,
              last_name: uk_donor_last_name,
              email: uk_donor_email,
              uk_gift_aid_accepted: uk_gift_aid_accepted
            }
          }.to_json
        end

        example 'DO not create a UK donor' do
          do_request

          expect(status).to eq(400)
          response = JSON.parse(response_body)

          expect(response['errors']['title'][0]).to eq("can't be blank")
          expect(response['errors']['house_name_or_number'][0]).to eq("can't be blank")
          expect(response['errors']['postcode'][0]).to eq("can't be blank")
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
        expect(response['errors']['donor'][0]).to eq("Could not find a donor with ID #{id}")
      end
    end

    context '404' do
      parameter :id, type: :string, required: true

      let(:id)  { unaffiliated_donor.id }

      example 'Invalid request: Search donor by id' do
        do_request

        expect(status).to eq(404)
        response = JSON.parse(response_body)
        expect(response['errors']['donor'][0]).to eq("Could not find a donor with ID #{id}")
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
