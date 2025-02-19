require 'rails_helper'

RSpec.describe 'GET partners/:partner_id/campaigns', type: :request do
  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(CampaignsController).to receive(:partner).and_return(partner)
  end

  context 'when the donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    it 'returns a successful response' do
      get partner_campaigns_path(partner)
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      get partner_campaigns_path(partner)
      expect(response).to render_template(:index)
    end

    it 'assigns the correct view model' do
      get partner_campaigns_path(partner)
      expect(assigns(:view_model).partner).to eq(partner)
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: nil))
    end

    it 'redirects to the edit partner path' do
      get partner_campaigns_path(partner)
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash error message' do
      get partner_campaigns_path(partner)
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a campaign for this partner")
    end
  end
end
