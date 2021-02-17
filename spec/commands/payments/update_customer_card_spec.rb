require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::UpdateCustomerCard do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }

  let(:billing_details_params) do
    {
      name: 'Donatello Donor',
      address: {
        postal_code: '19702'
      }
    }
  end

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

  context 'when a credit card can be added to the customer' do
    let(:payment_method) do
      Stripe::PaymentMethod.create({ type: 'card', card: card_params, billing_details: billing_details_params })
    end

    it 'updates the customer credit card' do
      command = Payments::UpdateCustomerCard.run(customer_id: 'test_cus_1', payment_method_id: payment_method[:id])

      expect(command).to be_success
      expect(command.result[:address_zip_code]).to eq('19702')
      expect(command.result[:name]).to eq('Donatello Donor')
      expect(command.result[:payment_processor_source_id]).to eq(payment_method[:id])
      expect(command.result[:payment_source_type]).to eq('card')
    end
  end

  context 'when a customer card cannot be created' do
    let(:payment_method) do
      Stripe::PaymentMethod.create({ type: 'card', card: card_params, billing_details: billing_details_params })
    end

    it 'fails with errors' do
      stripe_error = Stripe::StripeError.new('Some error message')
      StripeMock.prepare_error(stripe_error, :attach_payment_method)

      command = Payments::UpdateCustomerCard.run(customer_id: 'test_cus_1', payment_method_id: payment_method[:id])

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :stripe_error)
    end
  end
end
