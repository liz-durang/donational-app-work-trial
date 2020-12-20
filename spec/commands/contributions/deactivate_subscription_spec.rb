require 'rails_helper'

RSpec.describe Contributions::DeactivateSubscription do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do |example|
    create(:partner, :default)
  end

  context 'when is cancelled' do
    let(:subscription) do
      create(:subscription, donor: donor, deactivated_at: nil)
    end

    it 'deactivates subscription' do
      command = Contributions::DeactivateSubscription.run(subscription: subscription)

      expect(command).to be_success
      expect(subscription.reload).not_to be_active
      expect(TriggerSubscriptionCancelledWebhook.jobs.size).to eq(1)
    end
  end
end
