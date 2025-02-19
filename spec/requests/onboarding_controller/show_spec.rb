require 'rails_helper'

RSpec.describe 'GET /getting-started', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }

  context 'when the donor is logged in' do
    before do
      login_as(donor)
    end

    it 'returns a successful response' do
      get onboarding_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the show template' do
      get onboarding_path
      expect(response).to render_template(:show)
    end
  end

  context 'when the donor is not logged in' do
    before do
      allow(Donors::CreateAnonymousDonorAffiliatedWithPartner).to receive(:run!).and_return(donor)
    end

    it 'creates an anonymous donor affiliated with a partner' do
      expect(Donors::CreateAnonymousDonorAffiliatedWithPartner).to receive(:run!).and_return(donor)
      get onboarding_path
    end

    it 'returns a successful response' do
      get onboarding_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the show template' do
      get onboarding_path
      expect(response).to render_template(:show)
    end
  end
end
