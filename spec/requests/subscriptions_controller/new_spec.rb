require 'rails_helper'

RSpec.describe 'GET /take-the-pledge', type: :request do
  include Helpers::LoginHelper
  let!(:donor) { create(:donor) }
  let!(:payment_methnod) { create(:payment_method, donor:) }
  let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true) }
  let(:campaign) { create(:campaign, partner: partner) }

  before do
    login_as(donor)
    allow(Partners::GetPartnerById).to receive(:call).and_return(partner)
    allow(Partners::GetCampaignBySlug).to receive(:call).and_return(campaign)
    allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
    allow(Partners::GetOftwPartners).to receive(:call).and_return([partner])
    allow(Partners::GetChapterOptionsByPartnerOrCampaign).to receive(:call).and_return([])
    allow(Constants::GetTitles).to receive(:call).and_return(['Mr.', 'Ms.'])
    allow(Constants::GetLocalizedPaymentMethods).to receive(:call).and_return({'USD': [double(human_readable_name: 'card', payment_processor_payment_method_type_code: '123')]})
  end

  context 'when the partner and campaign are valid' do
    it 'returns a successful response' do
      get take_the_pledge_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get take_the_pledge_path
      expect(response).to render_template(:new)
    end

    it 'assigns the correct view model' do
      get take_the_pledge_path, params: { campaign_slug: campaign.slug}
      expect(assigns(:view_model).partners).to eq([partner])
      expect(assigns(:view_model).campaign).to eq(campaign)
      expect(assigns(:view_model).currency_code).to eq(partner.currency.upcase)
      expect(assigns(:view_model).minimum_contribution_amount).to eq([campaign.minimum_contribution_amount.to_i, SubscriptionsController::DEFAULT_MINIMUM_CONTRIBUTION].max)
      expect(assigns(:view_model).contribution_amount_help_text).to eq(campaign.contribution_amount_help_text || SubscriptionsController::DEFAULT_CONTRIBUTION_AMOUNT_HELP_TEXT)
      expect(assigns(:view_model).titles).to eq(['Mr.', 'Ms.'])
      expect(assigns(:view_model).payment_method_options.keys).to eq([:USD])
    end
  end

  context 'when the partner is not active or does not use the One for the World checkout' do
    before do
      allow(partner).to receive(:active?).and_return(false)
    end

    it 'returns a not found response' do
      get take_the_pledge_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when the campaign is not found' do
    before do
      allow(Partners::GetCampaignBySlug).to receive(:call).and_return(nil)
    end

    it 'returns a not found response' do
      get campaign_take_the_pledge_path(campaign.slug)
      expect(response).to have_http_status(:not_found)
    end
  end
end
