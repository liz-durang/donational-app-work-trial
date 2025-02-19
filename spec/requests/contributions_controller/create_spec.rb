require 'rails_helper'

RSpec.describe 'POST /contributions', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio) }
  let(:partner) { create(:partner) }
  let(:subscription) { create(:subscription, donor: donor) }
  let(:currency) { Money.default_currency }
  let(:contribution_params) do
    {
      subscription: {
        amount_dollars: 50,
        tips_cents: 200,
        frequency: 'monthly',
        portfolio_id: portfolio.id,
        payment_token: 'test_token',
        start_at: Time.zone.now
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ContributionsController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ContributionsController).to receive(:active_subscription).and_return(subscription)
    allow_any_instance_of(ContributionsController).to receive(:current_currency).and_return(currency)
  end

  context 'when the contribution is created successfully' do
    before do
      allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the edit accounts path' do
      post contributions_path, params: contribution_params
      expect(response).to redirect_to(edit_accounts_path)
    end

    it 'sets a flash success message' do
      post contributions_path, params: contribution_params
      expect(flash[:success]).to eq("We've updated your donation plan")
    end
  end

  context 'when the contribution creation fails' do
    before do
      allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the new contribution path' do
      post contributions_path, params: contribution_params
      expect(response).to redirect_to(new_contribution_path)
    end

    it 'sets a flash error message' do
      post contributions_path, params: contribution_params
      expect(flash[:alert]).to eq('Error message')
    end
  end
end
