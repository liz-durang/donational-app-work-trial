require 'rails_helper'

RSpec.describe Contributions::MigrateSubscriptionToNewPartner do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do |example|
    create(:partner, name: "Old Partner")
  end

  context 'when there is a new partner' do
    let(:subscription) do
      create(:subscription, donor: donor, partner: Partner.find_by(name: "Old Partner"), deactivated_at: nil)
    end

    let(:new_partner) { create(:partner, name: "New Partner") }

    it 'migrates the subscription' do
      expect(subscription.partner.name).to eq "Old Partner"
      command = Contributions::MigrateSubscriptionToNewPartner.run(subscription: subscription, partner: new_partner)
      expect(command).to be_success
      expect(Contributions::GetSubscriptionById.call(id: subscription.id).deactivated_at).to be_present
      expect(Contributions::GetActiveSubscription.call(donor: subscription.donor).partner.name).to eq "New Partner"
    end
  end
end
