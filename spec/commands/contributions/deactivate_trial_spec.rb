require 'rails_helper'

RSpec.describe Contributions::DeactivateTrial do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do
    create(:partner, :default)
  end

  context 'when is cancelled' do
    let(:subscription) do
      create(:subscription, donor:, trial_deactivated_at: nil, trial_amount_cents: 1000, start_at: 1.day.from_now)
    end

    it 'deactivates trial' do
      expect(subscription.trial_active?).to be true

      command = Contributions::DeactivateTrial.run(subscription:)

      expect(command).to be_success
      expect(subscription.reload.trial_active?).not_to be true
      expect(TriggerSubscriptionWebhook.jobs.size).to eq(1)
    end
  end
end
