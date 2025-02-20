require 'rails_helper'

RSpec.describe 'POST /get_setup_intent_client_secret', type: :request do
  let(:client_secret) { 'seti_1JH8Y2LzKZgNQ2xG1l9x8Y2L_secret_1234567890abcdef' }

  context 'when the client secret is generated successfully' do
    before do
      allow(Payments::GenerateSetupIntentClientSecret).to receive(:call).and_return(client_secret)
    end

    it 'returns a successful response' do
      post get_setup_intent_client_secret_path, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'returns the client secret in the response body' do
      post get_setup_intent_client_secret_path, xhr: true
      expect(JSON.parse(response.body)).to eq('client_secret' => client_secret)
    end
  end

  context 'when the client secret generation fails' do
    before do
      allow(Payments::GenerateSetupIntentClientSecret).to receive(:call).and_return(nil)
    end

    it 'returns an error response' do
      post get_setup_intent_client_secret_path, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'returns an error status in the response body' do
      post get_setup_intent_client_secret_path, xhr: true
      expect(JSON.parse(response.body)).to eq('status' => 500)
    end
  end
end
