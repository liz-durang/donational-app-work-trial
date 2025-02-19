require 'rails_helper'

RSpec.describe 'POST /:campaign_slug/contributions', type: :request do
  include Helpers::CommandHelper

  COMMAND_CLASSES = [
    Donors::UpdateDonor,
    Partners::AffiliateDonorWithPartner,
    Partners::UpdateCustomDonorInformation,
    Portfolios::SelectPortfolio,
    Payments::UpdatePaymentMethod,
    Contributions::CreateOrReplaceSubscription,
    Donors::CreateDonorAffiliatedWithPartner
  ].freeze

  let(:partner) { create(:partner) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:portfolio) { create(:portfolio) }
  let(:managed_portfolio) { create(:managed_portfolio, portfolio: portfolio, partner: partner) }
  let(:donor) { create(:donor) }
  let(:valid_params) do
    {
      campaign_slug: campaign.slug,
      campaign_contribution: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        title: 'Mr',
        house_name_or_number: '123',
        postcode: '12345',
        uk_gift_aid_accepted: true,
        amount_dollars: 50,
        frequency: 'monthly',
        partner_contribution_percentage: 10,
        start_at_month: Time.zone.today.month,
        start_at_year: Time.zone.today.year
      }
    }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(CampaignContributionsController).to receive(:managed_portfolio).and_return(managed_portfolio)
  end

  context 'when the request is valid' do
    context 'if current_donor not present' do
      it 'creates a new donor' do
        allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(nil)
        expect {
          post campaign_contributions_path(campaign_slug: campaign.slug), params: valid_params
        }.to change(Donor, :count).by(1)
      end
    end

    context 'on updating donor information' do
      before do
        allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
      end

      it 'updates the donor information' do
        expect(Donors::UpdateDonor).to receive(:run).with(hash_including(donor: donor)).and_return(successful_outcome)
        post campaign_contributions_path(campaign_slug: campaign.slug), params: valid_params
      end
    end

    context 'on successful outcome' do
      before do
        COMMAND_CLASSES.each do |command|
          allow(command).to receive(:run).and_return(successful_outcome)
        end
      end

      context 'if after donation thank you page is provided' do
        it 'redirects to thank you page' do
          partner.update(after_donation_thank_you_page_url: 'http://example.com/thank_you')
          post campaign_contributions_path(campaign_slug: campaign.slug), params: valid_params
          expect(response).to render_template('partners/_redirect')
        end
      end
  
      context 'if after donation thank you page is not provided' do
        it 'redirects portfolio path with modal' do
          post campaign_contributions_path(campaign_slug: campaign.slug), params: valid_params
          expect(response).to redirect_to(portfolio_path(show_modal: true))
        end
      end
    end

    context 'on failure outcome' do
      before do
        COMMAND_CLASSES.each do |command|
          allow(command).to receive(:run).and_return(failure_outcome)
        end
      end
  
      it 'redirects to the campaign path with an alert' do
        post campaign_contributions_path(campaign_slug: campaign.slug), params: valid_params
        expect(response).to redirect_to(campaigns_path(campaign.slug))
        expect(flash[:alert]).to eq('Error message')
      end
    end
  end
end
