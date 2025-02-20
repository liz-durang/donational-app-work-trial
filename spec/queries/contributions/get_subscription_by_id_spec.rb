require 'rails_helper'

RSpec.describe Contributions::GetSubscriptionById, type: :query do
  let(:subscription) { create(:subscription) }

  describe '#call' do
    subject { described_class.new.call(id: subscription_id) }

    context 'when the id is present' do
      let(:subscription_id) { subscription.id }

      it 'returns the subscription with the given id' do
        expect(subject).to eq(subscription)
      end
    end

    context 'when the id is blank' do
      let(:subscription_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the subscription with the given id does not exist' do
      let(:subscription_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
