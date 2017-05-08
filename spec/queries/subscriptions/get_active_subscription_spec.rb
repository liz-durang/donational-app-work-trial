require 'rails_helper'

RSpec.describe Subscriptions::GetActiveSubscription do
  let(:donor) { create(:donor) }

  subject { Subscriptions::GetActiveSubscription.call(donor: donor) }

  context 'when there are no active subscriptions' do
    before do
      allow_any_instance_of(Subscriptions::GetActiveSubscriptions)
        .to receive(:call)
        .with(donor: donor)
        .and_return(Subscription.none)
    end

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'when there are an existing active subscriptions' do
    before do
      allow_any_instance_of(Subscriptions::GetActiveSubscriptions)
        .to receive(:call)
        .with(donor: donor)
        .and_return([subscription_1, subscription_2])
    end

    let(:subscription_1) { instance_double(Subscription) }
    let(:subscription_2) { instance_double(Subscription) }

    it 'returns the first active subscription' do
      expect(subject).to eq subscription_1
    end
  end
end
