require 'rails_helper'

RSpec.describe 'POST /profiles/:username/contributions', type: :request do
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:referrer_donor) { create(:donor, username: 'referrer') }
  let(:partner) { create(:partner) }
  let(:portfolio) { create(:portfolio) }
  let(:profile_contribution_params) do
    {
      profile_contribution: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        referrer_donor_id: referrer_donor.id,
        portfolio_id: portfolio.id,
        amount_dollars: 50,
        frequency: 'monthly',
        payment_method_id: 'pm_test',
        payment_token: 'test_token',
        start_at_month: '12',
        start_at_year: '2023'
      }
    }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Donors::GetDonorById).to receive(:call).and_return(referrer_donor)
    allow(Portfolios::GetPortfolioById).to receive(:call).and_return(portfolio)
    allow(Partners::GetPartnerForDonor).to receive(:call).and_return(partner)
    allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(successful_outcome)
    allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(successful_outcome)
    allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
  end

  context 'when the contribution is created successfully' do
    it 'redirects to the portfolio path with show_modal set to true' do
      post profile_contributions_path(referrer_donor.username), params: profile_contribution_params
      expect(response).to redirect_to(portfolio_path(show_modal: true))
    end
  end

  context 'when the contribution creation fails' do
    before do
      allow_any_instance_of(Flow).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the profiles path with an alert message' do
      post profile_contributions_path(referrer_donor.username), params: profile_contribution_params
      expect(response).to redirect_to(profiles_path(referrer_donor.username))
      expect(flash[:alert]).to eq('Error message')
    end
  end
end
