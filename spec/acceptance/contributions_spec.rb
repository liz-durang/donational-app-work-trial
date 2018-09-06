require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contributions' do
  let(:contribution)  { Contribution.last }
  let(:donor)         { create(:donor) }
  let(:organization)  { create(:organization) }
  let(:partner)       { create(:partner) }
  let(:portfolio)     { create(:portfolio) }
  let(:api_key)       { partner.api_key }

  # Headers which should be included in the request
  header 'Content-Type', 'application/json'
  header 'X-Api-Key', :api_key

  # POST api/v1/donors/
  post '/api/v1/organizations/:id/contributions' do
    let(:id)  { organization.ein }
    # Request parameters
    parameter :donor_id, 'Donor who makes the contribution', type: :string, required: true
    parameter :amount, 'Contribution amount in USD', type: :string, required: true

    context '200' do
      let(:params) do
        {
          contribution: {
            donor_id: donor.id,
            amount: 20
          }
        }.to_json
      end

      example 'Succesfull request: Make a contribution to a single organization' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['contribution']['id']).to eq(contribution.id)
        expect(response['contribution']['portfolio_id']).to eq(contribution.portfolio_id)
        expect(response['contribution']['donor_id']).to eq(contribution.donor_id)
        expect(response['contribution']['amount']).to eq(contribution.amount_dollars)
      end
    end

    context '422' do
      context 'Invalid paramter: donor_id' do
        let(:params) do
          {
            contribution: {
              donor_id: '',
              amount: 20,
            }
          }.to_json
        end

        example 'Invalid request: Make a contribution to a single organization without donor' do
          explanation 'Invalid parameter: donor_id'
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq("Donor can't be nil")
        end
      end

      context 'Invalid parameter: amount' do
        let(:params) do
          {
            contribution: {
              donor_id: donor.id,
              amount: 0,
            }
          }.to_json
        end

        example 'Invalid request: Make a contribution to a single organization without amount' do
          explanation 'Invalid parameter: amount'
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq("Amount Cents is too small")
        end
      end
    end
  end

  post '/api/v1/portfolios/:id/contributions' do
    let(:id)  { portfolio.id }
    # Request parameters
    parameter :donor_id, 'Donor who makes the contribution', type: :string, required: true
    parameter :amount, 'Contribution amount in USD', type: :string, required: true

    context '200' do
      let(:params) do
        {
          contribution: {
            donor_id: donor.id,
            amount: 20
          }
        }.to_json
      end

      example 'Succesfull request: Make a contribution to a portfolio' do
        do_request

        expect(status).to eq(200)
        response = JSON.parse(response_body)
        expect(response['contribution']['id']).to eq(contribution.id)
        expect(response['contribution']['portfolio_id']).to eq(contribution.portfolio_id)
        expect(response['contribution']['donor_id']).to eq(contribution.donor_id)
        expect(response['contribution']['amount']).to eq(contribution.amount_dollars)
      end
    end

    context '422' do
      context 'Invalid paramter: donor_id' do
        let(:params) do
          {
            contribution: {
              donor_id: '',
              amount: 20,
            }
          }.to_json
        end

        example 'Invalid request: Make a contribution to a portfolio without donor' do
          explanation 'Invalid parameter: donor_id'
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq("Donor can't be nil")
        end
      end

      context 'Invalid parameter: amount' do
        let(:params) do
          {
            contribution: {
              donor_id: donor.id,
              amount: 0,
            }
          }.to_json
        end

        example 'Invalid request: Make a contribution to a portfolio without amount' do
          explanation 'Invalid parameter: amount'
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors'][0]).to eq("Amount Cents is too small")
        end
      end
    end
  end
end
