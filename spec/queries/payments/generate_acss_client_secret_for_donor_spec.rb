require 'rails_helper'

RSpec.describe Payments::GenerateAcssClientSecretForDonor, type: :query do
  let(:donor) { create(:donor) }
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call(donor:) }

    context 'when successful' do
      let(:setup_intent) { { client_secret: 'test_client_secret'} }
      let(:customer) { { id: 'test_customer_id' } }

      before do
        allow(service).to receive(:set_interval)
        allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)
        allow(service).to receive(:customer).and_return(customer)
        allow(Partners::GetPartnerForDonor).to receive(:call).and_return(double('Partner', payment_processor_account_id: 'test_account_id'))
      end

      it 'returns client_secret and customer_id' do
        expect(subject).to eq(%w[test_client_secret test_customer_id])
      end
    end

    context 'when Stripe raises an error' do
      before do
        allow(service).to receive(:set_interval)
        allow(service).to receive(:create_stripe_setup_intent).and_raise(Stripe::StripeError)
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(instance_of(Stripe::StripeError))
        expect(subject).to be_nil
      end
    end
  end

  describe '#create_stripe_setup_intent' do
    let(:customer_id) { 'test_customer_id' }
    let(:account_id) { 'test_account_id' }
    let(:setup_intent) { double('Stripe::SetupIntent') }

    before do
      allow(service).to receive(:customer_id).and_return(customer_id)
      allow(service).to receive(:account_id).and_return(account_id)
      allow(Stripe::SetupIntent).to receive(:create).and_return(setup_intent)
    end

    it 'creates a Stripe SetupIntent' do
      expect(Stripe::SetupIntent).to receive(:create).with(
        {
          payment_method_types: ['acss_debit'],
          customer: customer_id,
          payment_method_options: {
            acss_debit: {
              currency: 'cad',
              mandate_options: {
                payment_schedule: 'interval',
                interval_description: anything,
                transaction_type: 'personal'
              }
            }
          }
        },
        { stripe_account: account_id }
      )
      service.send(:create_stripe_setup_intent)
    end
  end

  describe '#set_interval' do
    let(:subscription) { double('Subscription', start_at: Date.today, frequency: 'monthly', trial_start_at: nil) }

    before do
      allow(service).to receive(:subscription).and_return(subscription)
    end

    it 'sets the interval description based on subscription frequency' do
      service.send(:set_interval)
      expect(service.instance_variable_get(:@interval_description)).to eq("on the 15th of every month, starting #{Date.today.strftime('%b')} #{Date.today.year}")
    end
  end
end
