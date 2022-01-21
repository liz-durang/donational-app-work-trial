require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::UpdateCustomerAcssDebitDetails do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  before { StripeMock.start }
  after { StripeMock.stop }
  let(:donor) { create(:donor) }
  let(:payment_method) { create(:payment_method, payment_processor_customer_id: 'test_cus_1') }
  let(:stripe_payment_method) do
    Stripe::PaymentMethod.create({ type: 'acss_debit', acss_debit: acss_params }, { stripe_account: account_id })
  end
  let(:account_id) { 'acc_123' }
  let(:acss_params) do
    {
      bank_name: 'STRIPE TEST BANK',
      fingerprint: 'KcwBulfLbOJknHIE',
      institution_number: '000',
      last4: '6789',
      transit_number: '11000'
    }
  end

  before do
    Stripe::Customer.create({}, { stripe_account: account_id })
  end

  context 'when the payment method can be added to the customer' do
    it 'attaches customer to payment method returning its details' do
      command = Payments::UpdateCustomerAcssDebitDetails.run(
        customer_id: 'test_cus_1',
        payment_method_id: stripe_payment_method[:id],
        donor_id: donor.id,
        account_id: account_id
      )

      expect(command).to be_success
      expect(command.result[:last4]).to eq('6789')
      expect(command.result[:name]).to eq('John Dolton')
      expect(command.result[:payment_source_type]).to eq('acss_debit')

      pm = Stripe::PaymentMethod.retrieve(stripe_payment_method[:id], { stripe_account: account_id })
      expect(pm[:customer]).to be_present
    end
  end

  context 'when the account verification is pending' do
    it 'fails with errors' do
      stripe_error = Stripe::StripeError.new('Some error message')
      StripeMock.prepare_error(stripe_error, :update_customer)

      command = Payments::UpdateCustomerAcssDebitDetails.run(
        customer_id: 'test_cus_1',
        payment_method_id: stripe_payment_method[:id],
        donor_id: donor.id,
        account_id: 'acc_123'
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :stripe_error)
    end
  end
end
