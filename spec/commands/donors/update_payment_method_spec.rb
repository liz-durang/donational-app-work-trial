require 'rails_helper'

RSpec.describe Donors::UpdatePaymentMethod do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:donor) { Donor.create(email: 'donor@example.com') }

  context 'when a payment token is supplied' do
    let(:payment_token) { 'tokenized_credit_card' }
    let(:successful_create_customer_response) do
      double(success?: true, result: 'cus_123')
    end

    it 'creates a customer a new customer in the payment gateway' do
      expect(Payments::CreateCustomer)
        .to receive(:run)
        .with(payment_token: 'tokenized_credit_card', email: 'donor@example.com')
        .and_return(successful_create_customer_response)

      outcome = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: payment_token)

      expect(outcome).to be_success

      donor.reload
      expect(donor.payment_processor_customer_id).to eq 'cus_123'
    end
  end

  context 'when a payment token is not supplied' do
    let(:payment_token) { '' }

    it 'fails with errors' do
      expect(Payments::CreateCustomer).not_to receive(:run)

      outcome = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: payment_token)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(payment_token: :empty)
    end
  end
end
