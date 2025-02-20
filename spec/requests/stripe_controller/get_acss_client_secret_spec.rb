require 'rails_helper'

RSpec.describe 'POST /get_acss_client_secret', type: :request do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:client_secret) { 'seti_1JH8Y2LzKZgNQ2xG1l9x8Y2L_secret_1234567890abcdef' }
  let(:customer_id) { 'cus_1234567890abcdef' }
  let(:setup_params) do
    {
      email: 'test@example.com',
      frequency: 'monthly',
      start_at_month: '12',
      start_at_year: '2023',
      trial: 'true',
      partner_id: partner.id
    }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Payments::GenerateAcssClientSecretForDonor).to receive(:call).and_return([client_secret, customer_id])
    allow(Payments::GenerateAcssClientSecret).to receive(:call).and_return([client_secret, customer_id])
  end

  context 'when the donor is logged in' do
    it 'returns a successful response' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'returns the client secret and customer id in the response body' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(JSON.parse(response.body)).to eq('client_secret' => client_secret, 'customer_id' => customer_id)
    end
  end

  context 'when the donor is not logged in' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(nil)
    end

    it 'returns a successful response' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'returns the client secret and customer id in the response body' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(JSON.parse(response.body)).to eq('client_secret' => client_secret, 'customer_id' => customer_id)
    end
  end

  context 'when the client secret generation fails' do
    before do
      allow(Payments::GenerateAcssClientSecretForDonor).to receive(:call).and_return([nil, nil])
      allow(Payments::GenerateAcssClientSecret).to receive(:call).and_return([nil, nil])
    end

    it 'returns an error response' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(response).to have_http_status(:success)
    end

    it 'returns an error status in the response body' do
      post get_acss_client_secret_path, params: setup_params, xhr: true
      expect(JSON.parse(response.body)).to eq('status' => 500)
    end
  end
end
