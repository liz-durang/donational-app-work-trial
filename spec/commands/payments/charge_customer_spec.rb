require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::ChargeCustomer do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:card_params) do
    {
      number: '4242424242424242',
      exp_month: 12,
      exp_year: 1.year.from_now.year,
      cvc: '999'
    }
  end
  let(:currency) { 'usd' }

  before { StripeMock.start }

  after { StripeMock.stop }

  before do
    Payments::CreateCustomer.run
    Payments::UpdateCustomerPaymentSource.run(
      customer_id: 'test_cus_1',
      payment_token: stripe_helper.generate_card_token(card_params)
    )
  end

  context 'when the customer id, account id and receipt email are supplied' do
    let(:customer_id) { 'test_cus_1' }
    let(:account_id) { 'test_acc_1' }
    let(:email) { 'user@example.com' }

    context 'and the stripe response is successful' do
      it "charges the donor's credit card" do
        command = Payments::ChargeCustomer.run(
          customer_id: customer_id,
          account_id: account_id,
          email: email,
          donation_amount_cents: 100,
          tips_cents: 23,
          platform_fee_cents: 2,
          currency: currency
        )

        expect(command).to be_success
      end
    end

    context 'and the stripe response is unsuccessful' do
      let(:error_message) { 'Some error message' }

      it 'fails with errors' do
        stripe_error = Stripe::StripeError.new(error_message)
        StripeMock.prepare_card_error(:card_declined)

        command = Payments::ChargeCustomer.run(
          customer_id: customer_id,
          account_id: account_id,
          email: email,
          donation_amount_cents: 100,
          currency: currency
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :stripe_error)
      end
    end
  end

  context 'when the customer id, account id, currency and email are not supplied' do
    let(:customer_id) { '' }
    let(:account_id) { '' }
    let(:email) { '' }
    let(:currency) { '' }

    it 'fails with errors' do
      command = Payments::ChargeCustomer.run(
        customer_id: customer_id,
        account_id: account_id,
        email: email,
        donation_amount_cents: 100,
        currency: currency
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer_id: :empty)
      expect(command.errors.symbolic).to include(account_id: :empty)
      expect(command.errors.symbolic).to include(email: :empty)
      expect(command.errors.symbolic).to include(currency: :empty)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
