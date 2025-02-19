require 'rails_helper'

RSpec.describe 'DELETE /contributions/:id', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:subscription) { create(:subscription, donor: donor) }
  let(:trial) { create(:subscription, donor: donor, trial_amount_cents: 100) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ContributionsController).to receive(:active_subscription).and_return(subscription)
    allow_any_instance_of(ContributionsController).to receive(:active_trial).and_return(trial)
  end

  context 'when cancelling a regular subscription' do
    before do
      allow(Contributions::DeactivateSubscription).to receive(:run).and_return(successful_outcome)
    end

    it 'deactivates the subscription' do
      expect(Contributions::DeactivateSubscription).to receive(:run).with(subscription: subscription)
      delete contribution_path(subscription)
    end

    it 'sets a flash success message' do
      delete contribution_path(subscription)
      expect(flash[:success]).to eq("We've cancelled your donation plan")
    end

    it 'redirects to the edit accounts path' do
      delete contribution_path(subscription)
      expect(response).to redirect_to(edit_accounts_path)
    end
  end

  context 'when cancelling a trial subscription' do
    before do
      allow(Contributions::DeactivateTrial).to receive(:run).and_return(successful_outcome)
    end

    it 'deactivates the trial' do
      expect(Contributions::DeactivateTrial).to receive(:run).with(subscription: trial)
      delete contribution_path(trial), params: { trial: true }
    end

    it 'sets a flash success message' do
      delete contribution_path(trial), params: { trial: true }
      expect(flash[:success]).to eq("We've cancelled your donation trial")
    end

    it 'redirects to the edit accounts path' do
      delete contribution_path(trial), params: { trial: true }
      expect(response).to redirect_to(edit_accounts_path)
    end
  end
end
