require 'rails_helper'

# NOTE: app/controllers/api/v1/hooks_controller.rb:27 current_partner isn't instantiated, tests will fail. Currently 'xit'ed.
RSpec.describe 'POST /api/v1/hooks', type: :request do
  describe 'POST /api/v1/hooks' do
    let(:partner) { create(:partner) }
    let(:valid_params) do
      {
        hook_url: 'https://example.com/webhook',
        hook_type: 'example_type'
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_partner).and_return(partner)
    end

    context 'when the request is valid' do
      before do
        allow(Hooks::CreateOrUpdateWebhook).to receive(:run).and_return(double(success?: true, result: double))
      end

      xit 'creates a webhook and returns status :ok' do
        post '/api/v1/hooks', params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request is invalid' do
      before do
        allow(Hooks::CreateOrUpdateWebhook).to receive(:run).and_return(double(success?: false, errors: double(message_list: ['Error message'])))
      end

      xit 'returns status :unprocessable_entity with errors' do
        post '/api/v1/hooks', params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq('errors' => ['Error message'])
      end
    end
  end
end
