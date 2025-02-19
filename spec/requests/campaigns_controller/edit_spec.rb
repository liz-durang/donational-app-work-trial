require 'rails_helper'

RSpec.describe 'GET partners/:partner_id/campaigns/:id/edit', type: :request do
  let(:partner) { create(:partner) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:donor) { create(:donor) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(CampaignsController).to receive(:partner).and_return(partner)
    allow_any_instance_of(CampaignsController).to receive(:campaign_by_id).and_return(campaign)
  end

  context 'when the donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    it 'returns a successful response' do
      get edit_partner_campaign_path(partner, campaign)
      expect(response).to have_http_status(:success)
    end

    it 'renders the edit template' do
      get edit_partner_campaign_path(partner, campaign)
      expect(response).to render_template(:edit)
    end

    it 'assigns the correct view model' do
      get edit_partner_campaign_path(partner, campaign)

      view_model = assigns(:view_model)
      expect(view_model.partner).to eq(partner)
      expect(view_model.campaign).to eq(campaign)
      expect(view_model.banner_image).to eq(campaign.banner_image)
      expect(view_model.default_contribution_amounts).to eq(campaign.default_contribution_amounts&.join(', ') || [])
      expect(view_model.minimum_contribution_amount).to eq(campaign.minimum_contribution_amount)
      expect(view_model.currency).to eq(Money::Currency.new(partner.currency))
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: nil))
    end

    it 'redirects to the edit partner path' do
      get edit_partner_campaign_path(partner, campaign)
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash error message' do
      get edit_partner_campaign_path(partner, campaign)
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a campaign for this partner")
    end
  end
end
