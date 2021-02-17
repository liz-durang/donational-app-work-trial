require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::RefundPaymentIntent do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:card_params) do
    {
      number: '4242424242424242',
      exp_month: 12,
      exp_year: 1.year.from_now.year,
      cvc: '999'
    }
  end

  before do
    Payments::CreateCustomer.run
  end

  context 'when the payment intent ID and account ID are supplied' do
    before do
      Stripe::PaymentMethod.attach(stripe_payment_method[:id], { customer: 'test_cus_1' })
    end

    let(:stripe_payment_method) { Stripe::PaymentMethod.create({ type: 'card', card: card_params }) }
    let(:account_id) { 'test_acc_1' }
    let(:payment_intent) do
      Stripe::PaymentIntent.create({
        amount: 100,
        confirm: true,
        currency: 'usd',
        customer: 'test_customer_1',
        payment_method: stripe_payment_method[:id],
        off_session: true,
        on_behalf_of: account_id,
        transfer_data: { destination: account_id }
      })
    end

    # Run this test once https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/714 is fixed.
    context 'and the stripe response is successful' do
      xit 'refunds the payment intent' do
        command = described_class.run(payment_intent_id: payment_intent.id)

        expect(command).to be_success
      end
    end

    context 'and the payment intent ID is invalid' do
      let(:error_message) { "No such payment intent: invalid ID" }

      it 'fails with errors' do
        stripe_error = Stripe::StripeError.new(error_message)
        command = described_class.run(payment_intent_id: 'invalid ID')

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :stripe_error)
      end
    end
  end

  context 'when the payment intent ID is not supplied' do
    let(:payment_intent_id) { '' }

    it 'fails with errors' do
      command = described_class.run(payment_intent_id: payment_intent_id)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_intent_id: :empty)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
