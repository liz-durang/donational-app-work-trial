require 'rails_helper'

RSpec.describe Contributions::DeactivateTrial do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do |example|
    create(:partner, :default)
  end

  context 'when is cancelled' do
    let(:subscription) do
      create(:subscription, donor: donor, trial_deactivated_at: nil)
    end

    it 'deactivates trial' do
      command = Contributions::DeactivateTrial.run(subscription: subscription)

      expect(command).to be_success
      expect(subscription.reload.trial_active?).not_to be true
      expect(TriggerSubscriptionWebhook.jobs.size).to eq(1)
    end
  end
end
