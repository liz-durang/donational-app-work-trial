require 'rails_helper'

RSpec.describe Payments::GetChargeFromDispute, type: :query do
  let(:account_id) { 'test_account_id' }
  let(:charge_id) { 'test_charge_id' }
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call(account_id: account_id, charge_id: charge_id) }

    context 'when successful' do
      let(:charge) { double('Stripe::Charge') }

      before do
        allow(Stripe::Charge).to receive(:retrieve).with(charge_id, { stripe_account: account_id }).and_return(charge)
      end

      it 'returns the charge' do
        expect(subject).to eq(charge)
      end
    end

    context 'when Stripe raises an InvalidRequestError' do
      before do
        allow(Stripe::Charge).to receive(:retrieve).and_raise(Stripe::InvalidRequestError.new('Invalid request', 'param', http_status: 400))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(instance_of(Stripe::InvalidRequestError))
        expect(subject).to be_nil
      end
    end

    context 'when Stripe raises a generic StripeError' do
      before do
        allow(Stripe::Charge).to receive(:retrieve).and_raise(Stripe::StripeError.new('Stripe error'))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(instance_of(Stripe::StripeError))
        expect(subject).to be_nil
      end
    end
  end
end
