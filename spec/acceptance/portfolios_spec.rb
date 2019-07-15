require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Portfolios' do
  let(:partner)             { create(:partner) }
  let(:api_key)             { partner.api_key }
  let(:portfolio)           { create(:portfolio) }
  let(:organization)        { create(:organization) }
  let!(:allocation)         { create(:allocation, organization: organization, portfolio: portfolio, percentage: 100) }
  let!(:managed_portfolio)  { create(:managed_portfolio, partner: partner, portfolio: portfolio) }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :api_key

  # GET api/v1/portfolios/
  get '/api/v1/portfolios' do
    context '200' do
      example 'Successful request: List Charitable Portfolios' do
        do_request

        expect(status).to eq(200)

        json = JSON.parse(response_body).with_indifferent_access
        expect(json[:portfolios][0][:id]).to eq(managed_portfolio.id)
        expect(json[:portfolios][0][:name]).to eq(managed_portfolio.name)
        expect(json[:portfolios][0][:allocations][0][:organization_ein]).to eq(managed_portfolio.portfolio.active_allocations.first.organization_ein)
        expect(json[:portfolios][0][:allocations][0][:percentage]).to eq(managed_portfolio.portfolio.active_allocations.first.percentage)
      end
    end
  end
end
