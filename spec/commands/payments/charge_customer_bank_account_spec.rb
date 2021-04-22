require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::ChargeCustomerBankAccount, skip: true do
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

  let(:account_id) { 'test_acc_1' }
  let(:currency) { 'usd' }
  let(:customer_id) { 'test_cus_1' }
  let(:donation_amount_cents) { 100 }
  let(:payment_method) { create(:payment_method, payment_processor_customer_id: 'test_cus_1') }

  before do
    Payments::CreateCustomer.run
    Payments::UpdateCustomerPaymentSource.run(
      customer_id: 'test_cus_1',
      payment_token: stripe_helper.generate_bank_token(bank_account_params)
    )
  end

  context 'when account ID, currency, donation amount and payment method are supplied' do
    context 'and the Stripe response is successful' do
      it "charges the donor's bank account" do
        command = Payments::ChargeCustomerBankAccount.run(
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
        StripeMock.prepare_error(stripe_error, :new_charge)

        command = Payments::ChargeCustomerBankAccount.run(
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

  context 'when account ID, currency, donation amount and payment method are not supplied' do
    let(:account_id) { '' }
    let(:currency) { '' }
    let(:donation_amount_cents) { nil }
    let(:payment_method) { nil }

    it 'fails with errors' do
      command = Payments::ChargeCustomerBankAccount.run(
        account_id: account_id,
        currency: currency,
        donation_amount_cents: donation_amount_cents,
        payment_method: payment_method,
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
