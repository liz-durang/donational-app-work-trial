require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Organizations' do
  let!(:searchable_organizations) { create_list(:searchable_organization, 2) }
  let(:partner)                   { create(:partner) }
  let(:api_key)                   { partner.api_key }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :api_key

  # Get api/v1/organizations/
  get '/api/v1/organizations' do
    # Request parameters
    parameter :name, type: :string, required: true

    let(:name)  { 'Charity' }

    context '200' do

      example 'Successful request: Search charitable organizations' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['organizations'][0]['ein']).to eq(searchable_organizations[0].formatted_ein)
        expect(response['organizations'][0]['name']).to eq(searchable_organizations[0].formatted_name)
        expect(response['organizations'][0]['state']).to eq(searchable_organizations[0].state)
      end
    end
  end

  get '/api/v1/organizations/:id' do
    # Request parameters
    parameter :id, type: :string, required: true

    let(:id)  { searchable_organizations[0].ein }

    context '200' do

      example 'Successful request: Search charitable organization by ein' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['organization']['ein']).to eq(searchable_organizations[0].formatted_ein)
        expect(response['organization']['name']).to eq(searchable_organizations[0].formatted_name)
        expect(response['organization']['state']).to eq(searchable_organizations[0].state)
      end
    end

    context '404' do
      parameter :id, type: :string, required: true

      let(:id)  { 'invalid_ein' }

      example 'Invalid request: Search charitable organization by ein' do
        do_request

        expect(status).to eq(404)
        response = JSON.parse(response_body)
        expect(response['error']).to eq("Could not find an organization with EIN #{id}")
      end
    end
  end
end
