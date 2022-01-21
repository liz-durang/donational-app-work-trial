require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::ChargeCustomerCard do
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

  let(:account_id) { 'test_acc_1' }
  let(:currency) { 'usd' }
  let(:customer_id) { 'test_cus_1' }
  let(:donation_amount_cents) { 100 }
  let(:payment_method) { create(:payment_method, payment_processor_customer_id: 'test_cus_1') }

  before do
    Payments::CreateCustomer.run
  end

  context 'when the account ID, currency, donation amount and payment method are supplied' do
    let(:stripe_payment_method) { Stripe::PaymentMethod.create({ type: 'card', card: card_params }) }

    before do
      Stripe::PaymentMethod.attach(stripe_payment_method[:id], { customer: 'test_cus_1' })
      payment_method.update(payment_processor_source_id: stripe_payment_method[:id])
    end

    context 'and the Stripe response is successful' do
      it "charges the donor's credit card" do
        command = Payments::ChargeCustomerCard.run(
          account_id: account_id,
          currency: currency,
          donation_amount_cents: donation_amount_cents,
          payment_method: payment_method,
          tips_cents: 23,
          platform_fee_cents: 2
        )

        expect(command).to be_success
      end
    end

    context 'and the Stripe response is unsuccessful' do
      it 'fails with errors' do
        stripe_error = Stripe::StripeError.new('Some error message')
        StripeMock.prepare_error(stripe_error, :new_payment_intent)

        command = Payments::ChargeCustomerCard.run(
          account_id: account_id,
          currency: currency,
          donation_amount_cents: donation_amount_cents,
          payment_method: payment_method,
          tips_cents: 23,
          platform_fee_cents: 2
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :stripe_error)
      end
    end
  end

  context 'when the account ID, currency, donation amount and payment method are not supplied' do
    let(:account_id) { '' }
    let(:currency) { '' }
    let(:donation_amount_cents) { nil }
    let(:payment_method) { nil }

    it 'fails with errors' do
      command = Payments::ChargeCustomerCard.run(
        account_id: account_id,
        currency: currency,
        donation_amount_cents: donation_amount_cents,
        payment_method: payment_method
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(account_id: :empty)
      expect(command.errors.symbolic).to include(currency: :empty)
      expect(command.errors.symbolic).to include(donation_amount_cents: :nils)
      expect(command.errors.symbolic).to include(payment_method: :nils)

    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
