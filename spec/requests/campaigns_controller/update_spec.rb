require 'rails_helper'

RSpec.describe 'PUT partners/:partner_id/campaigns/:id', type: :request do
  include Helpers::CommandHelper

  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:campaign_params) do
    {
      title: 'Updated Campaign',
      description: 'Updated Description',
      slug: 'updated-campaign',
      banner_image: 'updated_banner_image_url',
      default_contribution_amounts: '15, 25, 35',
      minimum_contribution_amount: 10,
      contribution_amount_help_text: 'Updated help text',
      allow_one_time_contributions: false
    }
  end

  before do
    allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id)) # ensure_donor_has_permission!
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(CampaignsController).to receive(:partner).and_return(partner)
    allow_any_instance_of(CampaignsController).to receive(:campaign_by_id).and_return(campaign)
  end

  context 'when the campaign is updated successfully' do
    before do
      allow(Campaigns::UpdateCampaign).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the edit partner campaign path' do
      put partner_campaign_path(partner, campaign), params: { campaign: campaign_params }
      expect(response).to redirect_to(edit_partner_campaign_path(partner, campaign))
    end

    it 'sets a flash success message' do
      put partner_campaign_path(partner, campaign), params: { campaign: campaign_params }
      expect(flash[:success]).to eq('Campaign updated successfully.')
    end
  end

  context 'when the campaign update fails' do
    before do
      allow(Campaigns::UpdateCampaign).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the edit partner campaign path' do
      put partner_campaign_path(partner, campaign), params: { campaign: campaign_params }
      expect(response).to redirect_to(edit_partner_campaign_path(partner, campaign))
    end

    it 'sets a flash error message' do
      put partner_campaign_path(partner, campaign), params: { campaign: campaign_params }
      expect(flash[:error]).to eq('Error message')
    end
  end
end
