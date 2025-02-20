require 'rails_helper'

RSpec.describe 'POST /get_bank_token', type: :request do
  let(:donor) { create(:donor) }
  let(:public_token) { 'public-sandbox-12345678-1234-1234-1234-123456789012' }
  let(:bank_account_id) { 'bank_account_id' }
  let(:plaid_response) { { access_token: 'access-sandbox-12345678-1234-1234-1234-123456789012', item_id: 'item_id' } }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
  end

  context 'when the bank token is created successfully' do
    before do
      allow(Payments::GeneratePlaidBankToken).to receive(:call).and_return(plaid_response)
    end

    it 'returns a successful response' do
      post get_bank_token_path, params: { public_token: public_token, bank_account_id: bank_account_id }
      expect(response).to have_http_status(:success)
    end

    it 'returns the access token and item id' do
      post get_bank_token_path, params: { public_token: public_token, bank_account_id: bank_account_id }
      expect(JSON.parse(response.body)).to eq({ 'bank_account_token' => plaid_response.stringify_keys })
    end
  end

  context 'when the bank token creation fails' do
    before do
      allow(Payments::GeneratePlaidBankToken).to receive(:call).and_return(false)
    end

    it 'returns an error response' do
      post get_bank_token_path, params: { public_token: public_token, bank_account_id: bank_account_id }
      expect(response).to have_http_status(200)
    end

    it 'returns the error message' do
      post get_bank_token_path, params: { public_token: public_token, bank_account_id: bank_account_id }
      expect(JSON.parse(response.body)).to eq('status' => 500)
    end
  end
end
