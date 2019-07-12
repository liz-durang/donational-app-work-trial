require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Donors' do
  let(:donor)   { Donor.last }
  let(:partner) { create(:partner) }
  let(:api_key) { partner.api_key }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :api_key

  # POST api/v1/donors/
  post '/api/v1/donors' do
    # Request parameters
    parameter :first_name, 'Donor first name', type: :string, required: true
    parameter :last_name, 'Donor last name', type: :string, required: true
    parameter :email, 'Donor email', type: :string, required: true

    context '200' do
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

    context '422' do
      let(:params) do
        {
          donor: {
            first_name: '',
            last_name: '',
            email: ''
          }
        }.to_json
      end

      example 'Invalid request: Create a donor' do
        do_request

        expect(status).to eq(422)
        response = JSON.parse(response_body)
        expect(response['errors'][0]).to eq("First Name can't be blank")
        expect(response['errors'][1]).to eq("Last Name can't be blank")
        expect(response['errors'][2]).to eq("Email can't be blank")
      end
    end
  end
end
