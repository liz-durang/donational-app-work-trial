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

  let(:card_params) do
    {
      number: '4242424242424242',
      exp_month: 12,
      exp_year: 1.year.from_now.year,
      cvc: '999'
    }
  end

  before do
    Payments::CreateCustomer.run(email: 'user@example.com')
  end

  context 'when a card can be added to the customer' do
    let(:payment_token) { stripe_helper.generate_card_token(card_params) }

    it 'updates the customer card' do
      command = Payments::UpdateCustomerPaymentSource.run(customer_id: 'test_cus_1', payment_token: payment_token)

      expect(command).to be_success
      expect(command.result[:last4]).to eq('4242')
    end
  end

  context 'when a customer card cannot be created' do
    let(:payment_token) { stripe_helper.generate_card_token(card_params) }

    it 'fails with errors' do
      stripe_error = Stripe::StripeError.new('Some error message')
      StripeMock.prepare_error(stripe_error, :update_customer)

      command = Payments::UpdateCustomerPaymentSource.run(customer_id: 'test_cus_1', payment_token: payment_token)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :stripe_error)
    end
  end
end
