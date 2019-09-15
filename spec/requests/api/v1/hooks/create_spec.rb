require 'rails_helper'

describe 'POST api/v1/hooks/', type: :request do
  let(:webhook)           { ZapierWebhook.last }
  let(:partner)           { create(:partner) }
  let(:failed_response)   { 422 }

  describe 'POST create' do
    let(:hook_type)         { 'new_donor' }
    let(:hook_url)          { 'https://hooks.zapier.com/hooks/fake/' }
    let(:updated_hook_url)  { 'https://hooks.zapier.com/hooks/updated_fake/' }

    let(:hook_params) do
      {
        hook_type: hook_type,
        hook_url: hook_url
      }
    end

    let(:updated_hook_params) do
      {
        hook_type: hook_type,
        hook_url: updated_hook_url
      }
    end

    let(:invalid_hook_url_params) do
      {
        hook_type: hook_type
      }
    end

    let(:invalid_hook_type_params) do
      {
        hook_url: hook_url
      }
    end

    context 'zapier webhook' do
      it 'returns a successful response' do
        post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates the webhook' do
        expect {
          post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(ZapierWebhook, :count).by(1)
      end

      it 'returns the webhook' do
        post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:webhook][:id]).to eq(webhook.id)
        expect(json[:webhook][:hook_type]).to eq(webhook.hook_type)
        expect(json[:webhook][:hook_url]).to eq(webhook.hook_url)
      end
    end

    context 'update existent zapier webhook' do
      it 'returns a successful response' do
        post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        post api_v1_hooks_path, params: updated_hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'updates the existent webhook' do
        expect {
          post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          post api_v1_hooks_path, params: updated_hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(ZapierWebhook, :count).by(1)
      end

      it 'returns the updated webhook' do
        post api_v1_hooks_path, params: hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        post api_v1_hooks_path, params: updated_hook_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:webhook][:id]).to eq(webhook.id)
        expect(json[:webhook][:hook_type]).to eq(webhook.hook_type)
        expect(json[:webhook][:hook_url]).to eq(updated_hook_url)
      end
    end

    context 'when the hook type is not correct' do
      it 'does not create a webhook' do
        expect {
          post api_v1_hooks_path, params: invalid_hook_type_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { ZapierWebhook.count }
      end

      it 'does not return a successful response' do
        post api_v1_hooks_path, params: invalid_hook_type_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(response.status).to eq(failed_response)
        expect(json[:errors][0]).to eq("Hook Type can't be nil")
      end
    end

    context 'when the hook url is not correct' do
      it 'does not create a webhook' do
        expect {
          post api_v1_hooks_path, params: invalid_hook_url_params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.not_to change { ZapierWebhook.count }
      end

      it 'does not return a successful response' do
        post api_v1_hooks_path, params: invalid_hook_url_params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(response.status).to eq(failed_response)
        expect(json[:errors][0]).to eq("Hook Url can't be nil")
      end
    end
  end
end
