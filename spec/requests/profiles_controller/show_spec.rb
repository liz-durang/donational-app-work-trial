require 'rails_helper'

RSpec.describe 'GET /profiles/:username', type: :request do
  let(:donor) { create(:donor, username: 'john_doe') }
  let(:partner) { create(:partner) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:organizations) { create_list(:organization, 3) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:link_token) { 'link-sandbox-12345678-1234-1234-1234-123456789012' }

  before do
    allow(Donors::GetDonorByUsername).to receive(:call).and_return(donor)
    allow(Portfolios::GetActivePortfolio).to receive(:call).and_return(portfolio)
    allow(Portfolios::GetActiveAllocations).to receive(:call).and_return(organizations.map { |org| double(organization: org) })
    allow(Partners::GetPartnerForDonor).to receive(:call).and_return(partner)
    allow(Partners::GetPartnerAffiliationByDonor).to receive(:call).and_return(double(campaign: campaign))
    allow(Payments::GeneratePlaidLinkToken).to receive(:call).and_return(link_token)
  end

  context 'when the donor is found' do
    it 'returns a successful response' do
      get profiles_path(donor.username)
      expect(response).to have_http_status(:success)
    end

    it 'renders the show template' do
      get profiles_path(donor.username)
      expect(response).to render_template(:show)
    end

    it 'assigns the correct view model' do
      get profiles_path(donor.username)
      expect(assigns(:view_model).donor).to eq(donor)
      expect(assigns(:view_model).organizations).to eq(organizations)
      expect(assigns(:view_model).new_profile_contribution).to be_an_instance_of(ProfileContribution)
      expect(assigns(:view_model).portfolio_id).to eq(portfolio.id)
      expect(assigns(:view_model).link_token).to eq(link_token)
      expect(assigns(:view_model).show_plaid?).to eq(partner.supports_plaid?)
      expect(assigns(:view_model).currency).to eq(Money::Currency.new(partner.currency))
      expect(assigns(:view_model).default_contribution_amounts).to eq(campaign.default_contribution_amounts)
      expect(assigns(:view_model).minimum_contribution_amount).to eq(campaign.minimum_contribution_amount)
      expect(assigns(:view_model).donation_frequencies).to eq(Subscription.frequency.options.select { |_k, v| v.in? %w[once monthly] })
    end
  end

  context 'when the donor is not found' do
    before do
      allow(Donors::GetDonorByUsername).to receive(:call).and_return(nil)
    end

    it 'returns a not found response' do
      get profiles_path('nonexistent_user')
      expect(response).to have_http_status(:not_found)
    end
  end
end
