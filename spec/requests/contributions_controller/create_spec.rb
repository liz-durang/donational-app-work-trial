require 'rails_helper'

RSpec.describe 'POST /contributions', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio) }
  let(:partner) { create(:partner) }
  let(:subscription) { create(:subscription, donor:) }
  let(:currency) { Money.default_currency }
  let(:contribution_params) do
    {
      subscription: {
        amount_dollars: 50,
        tips_cents: 200,
        frequency: 'monthly',
        portfolio_id: portfolio.id,
        payment_token: 'test_token',
        start_at: Time.zone.now.iso8601
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ContributionsController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ContributionsController).to receive(:active_subscription).and_return(subscription)
    allow_any_instance_of(ContributionsController).to receive(:current_currency).and_return(currency)
    allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)
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

    it 'tracks an analytics event' do
      post contributions_path, params: contribution_params
      expect(flash[:analytics]).to include(['Goal: Donation', { revenue: 50 }])
    end

    it 'passes the correct parameters to CreateOrReplaceSubscription' do
      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(
          donor:,
          portfolio:,
          partner:,
          frequency: 'monthly',
          amount_cents: 5000,
          tips_cents: 200,
          partner_contribution_percentage: 0
        )
      ).and_return(successful_outcome)

      post contributions_path, params: contribution_params
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

  context 'when parsing different parameter values' do
    before do
      allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
    end

    it 'handles different frequencies' do
      params = contribution_params
      params[:subscription][:frequency] = 'quarterly'

      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(frequency: 'quarterly')
      ).and_return(successful_outcome)

      post contributions_path, params:
    end

    it 'handles different amounts' do
      params = contribution_params
      params[:subscription][:amount_dollars] = 100

      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(amount_cents: 10_000)
      ).and_return(successful_outcome)

      post contributions_path, params:
    end

    it 'correctly parses the start_at parameter' do
      specific_time = Time.zone.parse('2023-01-01T10:00:00Z')
      params = contribution_params
      params[:subscription][:start_at] = specific_time.iso8601

      allow(Time.zone).to receive(:parse).with(specific_time.iso8601).and_return(specific_time)

      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(start_at: specific_time)
      ).and_return(successful_outcome)

      post contributions_path, params:
    end

    it 'handles missing start_at parameter' do
      params = contribution_params
      params[:subscription].delete(:start_at)

      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(start_at: nil)
      ).and_return(successful_outcome)

      post contributions_path, params:
    end

    it 'handles tips_cents parameter' do
      params = contribution_params
      params[:subscription][:tips_cents] = 500

      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(tips_cents: 500)
      ).and_return(successful_outcome)

      post contributions_path, params:
    end
  end
end
