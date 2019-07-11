require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Organizations' do
  let!(:searchable_organization) { create_list(:searchable_organization, 2) }
  let(:partner)                  { create(:partner) }
  let(:api_key)                  { partner.api_key }

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
        expect(response['organizations'][0]['ein']).to eq(searchable_organization[0].formatted_ein)
        expect(response['organizations'][0]['name']).to eq(searchable_organization[0].name)
        expect(response['organizations'][0]['state']).to eq(searchable_organization[0].state)
      end
    end
  end
end
