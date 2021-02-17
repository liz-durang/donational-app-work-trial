require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::UpdateCustomerPaymentSource do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }

  let(:bank_account_params) do
    {
      account_holder_name: 'Donatello Donor',
      account_holder_type: 'individual',
      country: 'US',
      routing_number: '110000000',
      account_number: '000123456789'
    }
  end

  before do
    Payments::CreateCustomer.run(email: 'user@example.com')
  end

  context 'when a bank account can be added to the customer' do
    let(:payment_token) { stripe_helper.generate_bank_token(bank_account_params) }

    it 'updates the customer card' do
      command = Payments::UpdateCustomerPaymentSource.run(customer_id: 'test_cus_1', payment_token: payment_token)

      expect(command).to be_success
      expect(command.result[:last4]).to eq('6789')
      expect(command.result[:name]).to eq('Donatello Donor')
      expect(command.result[:payment_source_type]).to eq('bank_account')
    end
  end

  context 'when a customer card cannot be created' do
    let(:payment_token) { stripe_helper.generate_bank_token(bank_account_params) }

    it 'fails with errors' do
      stripe_error = Stripe::StripeError.new('Some error message')
      StripeMock.prepare_error(stripe_error, :update_customer)

      command = Payments::UpdateCustomerPaymentSource.run(customer_id: 'test_cus_1', payment_token: payment_token)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :stripe_error)
    end
  end
end
