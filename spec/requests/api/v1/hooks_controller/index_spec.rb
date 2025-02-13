require 'rails_helper'

RSpec.describe 'GET /api/v1/hooks', type: :request do
  context 'when the request is valid' do
    it 'returns a successful response' do
      get '/api/v1/hooks'

      expect(response).to have_http_status(:success)
    end
  end
end
