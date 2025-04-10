require 'rails_helper'

RSpec.describe Payments::GenerateSetupIntentClientSecret, type: :query do
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call }

    context 'when successful' do
      let(:setup_intent) { { client_secret: 'test_client_secret' } }

      before do
        allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)
      end

      it 'returns the client_secret' do
        expect(subject).to eq('test_client_secret')
      end
    end

    context 'when Stripe raises an error' do
      before do
        allow(Stripe::SetupIntent).to receive(:create).and_raise(Stripe::StripeError)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
