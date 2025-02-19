require 'rails_helper'

RSpec.describe 'POST partners/:partner_id/campaigns', type: :request do
  include Helpers::CommandHelper

  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:campaign_params) do
    {
      title: 'New Campaign',
      description: 'Campaign Description',
      slug: 'new-campaign',
      banner_image: 'banner_image_url',
      default_contribution_amounts: '10, 20, 30',
      minimum_contribution_amount: 5,
      contribution_amount_help_text: 'Help text',
      allow_one_time_contributions: true
    }
  end

  before do
    allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id)) # ensure_donor_has_permission!
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(CampaignsController).to receive(:partner).and_return(partner)
  end

  context 'when the campaign is created successfully' do
    before do
      allow(Campaigns::CreateCampaign).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the partner campaigns path' do
      post partner_campaigns_path(partner), params: { campaign: campaign_params }
      expect(response).to redirect_to(partner_campaigns_path(partner))
    end

    it 'sets a flash success message' do
      post partner_campaigns_path(partner), params: { campaign: campaign_params }
      expect(flash[:success]).to eq('Campaign created successfully.')
    end
  end

  context 'when the campaign creation fails' do
    before do
      allow(Campaigns::CreateCampaign).to receive(:run).and_return(double(success?: false, errors: double(message_list: ['Error message'])))
    end

    it 'redirects to the partner campaigns path' do
      post partner_campaigns_path(partner), params: { campaign: campaign_params }
      expect(response).to redirect_to(partner_campaigns_path(partner))
    end

    it 'sets a flash error message' do
      post partner_campaigns_path(partner), params: { campaign: campaign_params }
      expect(flash[:error]).to eq('Error message')
    end
  end
end
