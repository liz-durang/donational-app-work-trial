require 'rails_helper'

RSpec.describe Auth0Controller, type: :request do
  include Helpers::LoginHelper
  describe 'GET /auth/auth0/callback' do
    let(:donor) { create(:donor) }
    let(:auth_hash) do
      {
        'provider' => 'auth0',
        'uid' => '12345',
        'info' => {
          'email' => donor.email
        }
      }
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(auth_hash)
      allow(Donors::FindDonorFromAuth).to receive(:run!).and_return(donor)
    end

    context 'when a matching donor is found' do
      it 'logs in the donor and redirects to the portfolio path' do
        get '/auth/oauth2/callback'
        expect(response).to redirect_to(portfolio_path)
        login_as(donor)
        follow_redirect!
        expect(response.body).to include('Your personal charity portfolio')
      end
    end

    context 'when no matching donor is found' do
      before do
        allow(Donors::FindDonorFromAuth).to receive(:run!).and_return(nil)
      end

      it 'redirects to the root path' do
        get '/auth/oauth2/callback'
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
