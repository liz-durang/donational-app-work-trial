require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Organizations', search: true do
  let!(:searchable_organization_1) { create(:searchable_organization, :reindex, name: 'Charity 1') }
  let!(:searchable_organization_2) { create(:searchable_organization, :reindex, name: 'Charity 2') }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'

  # Get api/v1/organizations/
  get '/api/v1/organizations' do
    # Request parameters
    parameter :name, type: :string, required: true

    let(:name)  { 'Charity' }

    context '200' do
      example 'Successful request: Search charitable organizations' do
        SearchableOrganization.search_index.refresh
        sleep 5

        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['organizations'][0]['ein']).to eq(searchable_organization_1.formatted_ein)
        expect(response['organizations'][0]['name']).to eq(searchable_organization_1.formatted_name)
        expect(response['organizations'][0]['state']).to eq(searchable_organization_1.state)
      end
    end
  end

  get '/api/v1/organizations/:id' do
    # Request parameters
    parameter :id, type: :string, required: true

    let(:id)  { searchable_organization_1.ein }

    context '200' do

      example 'Successful request: Search charitable organization by ein' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['organization']['ein']).to eq(searchable_organization_1.formatted_ein)
        expect(response['organization']['name']).to eq(searchable_organization_1.formatted_name)
        expect(response['organization']['state']).to eq(searchable_organization_1.state)
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