require 'rails_helper'

RSpec.describe 'GET partners/:partner_id/campaigns/new', type: :request do
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
      get new_partner_campaign_path(partner)
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get new_partner_campaign_path(partner)
      expect(response).to render_template(:new)
    end

    it 'assigns the correct view model' do
      get new_partner_campaign_path(partner)
      expect(assigns(:view_model).partner).to eq(partner)
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: nil))
    end

    it 'redirects to the edit partner path' do
      get new_partner_campaign_path(partner)
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash error message' do
      get new_partner_campaign_path(partner)
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a campaign for this partner")
    end
  end
end
