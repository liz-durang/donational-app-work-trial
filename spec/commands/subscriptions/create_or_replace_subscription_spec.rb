require 'rails_helper'

RSpec.describe Subscriptions::CreateOrReplaceSubscription do
  subject do
    Subscriptions::CreateOrReplaceSubscription.run(subscription_params)
  end

  let(:subscription_params) do
    { donor: donor, donation_rate: 0.01, annual_income_cents: 80_000_00 }
  end
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  context 'when there are no existing subscriptions for the donor' do
    it 'creates a new active subscription' do
      expect { subject }.to change { Subscription.count }.from(0).to(1)

      subscription = Subscriptions::GetActiveSubscription.call(donor: donor)

      expect(subscription).to be_active
      expect(subscription.donation_rate).to eq 0.01
      expect(subscription.pay_in_frequency).to eq 'monthly'
    end
  end

  context 'when there is an existing active subscription' do
    let!(:existing_subscription) do
      create(:subscription, donor: donor, deactivated_at: nil)
    end

    let!(:subscription_for_other_donor) do
      create(:subscription, donor: other_donor, deactivated_at: nil)
    end

    it 'deactivates the previous subscriptions for the donor' do
      expect { subject }.not_to(change { subscription_for_other_donor.active? })

      expect(existing_subscription.reload).not_to be_active
    end

    it 'creates a new active subscription for the donor' do
      expect { subject }.to change { Subscription.count }.from(2).to(3)

      subscription = Subscriptions::GetActiveSubscription.call(donor: donor)
      expect(subscription).to be_active
      expect(subscription.donor).to eq donor
    end
  end
end
