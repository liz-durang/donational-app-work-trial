require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contributions' do
  let(:contribution)  { Contribution.last }
  let(:donor)         { create(:donor) }
  let(:organization)  { create(:organization) }
  let(:partner)       { create(:partner) }
  let(:portfolio)     { create(:portfolio) }
  let!(:allocation)   { create(:allocation, organization: organization, portfolio: portfolio, percentage: 100) }
  let(:api_key)       { partner.api_key }

  # Headers which should be included in the request
  header 'Content-Type',  'application/json'
  header 'X-Api-Key',     :api_key

  # POST api/v1/contributions
  post '/api/v1/contributions' do
    # Request parameters
    parameter :donor_id, 'Donor who makes the contribution', type: :string, required: true
    parameter :amount_cents, 'Contribution amount in cents (USD)', type: :integer, required: true
    parameter :currency, 'Contribution currency. Currently only USD is supported', type: :string, required: true
    parameter :organization_ein, 'The tax id of the recipient charitable organization', type: :string, required: false
    parameter :portfolio_id, 'The id of the charitable Portfolio to contribute to', type: :string, required: false
    parameter :external_reference_id, 'The contribution id on your platform', type: :string, required: false
    parameter :mark_as_paid, 'Indicates if the contribution was processed manually', type: :boolean, required: false
    parameter :receipt, 'The contribution receipt', type: :json, required: false

    explanation 'Contributions must be created with either an organization_ein or a portfolio_id.'

    context '200' do
      context 'Single organization' do
        let(:mark_as_paid) { true }
        let(:receipt) {
          {
            method: "ACH",
            account: "jp_morgan_chase_1",
            memo: "some_entry_id",
            transfer_date: "2019-01-01"
          }
        }

        let(:params) do
          {
            contribution: {
              donor_id: donor.id,
              amount_cents: 200,
              currency: 'USD',
              organization_ein: organization.ein,
              external_reference_id: 'external_reference_id_1',
              mark_as_paid: mark_as_paid,
              receipt: receipt
            }
          }.to_json
        end

        example 'Successful request: Make a contribution to a single organization' do
          do_request

          expect(status).to eq(200)
          response = JSON.parse(response_body)
          expect(response['contribution']['id']).to eq(contribution.id)
          expect(response['contribution']['portfolio_id']).to eq(contribution.portfolio_id)
          expect(response['contribution']['donor_id']).to eq(contribution.donor_id)
          expect(response['contribution']['amount_cents']).to eq(contribution.amount_cents)
          expect(response['contribution']['external_reference_id']).to eq(contribution.external_reference_id)
          expect(response['contribution']['processed_at']).not_to be(nil)
          expect(response['contribution']['receipt']).to eq(contribution.receipt)
        end
      end

      context 'Portfolio' do
        let(:params) do
          {
            contribution: {
              donor_id:     donor.id,
              amount_cents: 200,
              currency:     'USD',
              portfolio_id: portfolio.id
            }
          }.to_json
        end

        example 'Successful request: Make a contribution to a portfolio' do
          do_request

          expect(status).to eq(200)
          response = JSON.parse(response_body)
          expect(response['contribution']['id']).to eq(contribution.id)
          expect(response['contribution']['portfolio_id']).to eq(contribution.portfolio_id)
          expect(response['contribution']['donor_id']).to eq(contribution.donor_id)
          expect(response['contribution']['amount_cents']).to eq(contribution.amount_cents)
          expect(response['contribution']['external_reference_id']).to eq(contribution.external_reference_id)
          expect(response['contribution']['processed_at']).to be(nil)
          expect(response['contribution']['receipt']).to eq(contribution.receipt)
        end
      end
    end

    context '422' do
      context 'Single organization' do
        context 'Invalid parameter: donor_id' do
          let(:params) do
            {
              contribution: {
                donor_id:         '',
                amount_cents:     200,
                currency:         'USD',
                organization_ein: organization.ein
              }
            }.to_json
          end

          example 'Invalid request: Make a contribution to a single organization without donor' do
            explanation 'Invalid parameter: donor_id'
            do_request

            expect(status).to eq(422)
            response = JSON.parse(response_body)
            expect(response['errors'][0]).to eq("Suggested By can't be nil")
          end
        end

        context 'Invalid parameter: amount' do
          let(:params) do
            {
              contribution: {
                donor_id:         donor.id,
                amount_cents:     50,
                currency:         'USD',
                organization_ein: organization.ein
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

      context 'Portfolio' do
        context 'Invalid parameter: donor_id' do
          let(:params) do
            {
              contribution: {
                donor_id:     '',
                amount_cents: 200,
                currency:     'USD',
                portfolio_id: portfolio.id
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
                donor_id:     donor.id,
                amount_cents: 0,
                currency:     'USD',
                portfolio_id: portfolio.id
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

      context 'Invalid parameters: missing organization_ein and portfolio_id' do
        let(:params) do
          {
            contribution: {
              donor_id:         donor.id,
              amount_cents:     200,
              currency:         'USD'
            }
          }.to_json
        end

        example 'Invalid request: Make a contribution without organization_ein or portfolio_id' do
          explanation 'Invalid parameters: missing organization_ein and portfolio_id'
          do_request

          expect(status).to eq(422)
          response = JSON.parse(response_body)
          expect(response['errors']).to eq('Either Organization ein or Portfolio id should be present')
        end
      end
    end
  end
end
