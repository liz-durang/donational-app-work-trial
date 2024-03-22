require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::PlatformAccount::ChargeCustomerUsBankAccount do
  let(:currency) { 'usd' }
  let(:donation_amount_cents) { 100 }
  let(:charge_params) do
    {
      account_id:,
      currency:,
      donation_amount_cents:,
      payment_method:,
      tips_cents:,
      platform_fee_cents:,
      metadata:
    }
  end
  let(:platform_fee_cents) { 2 }
  let(:metadata) { { 'donor_id' => '123', 'portfolio_id' => '234', 'contribution_id' => '345' } }
  let(:tips_cents) { 23 }
  let(:bank_account_params) do
    {
      account_holder_type: 'individual',
      routing_number: '110000000',
      account_number: '000123456789'
    }
  end

  describe "tests NOT using Stripe's live test server" do
    subject do
      Payments::PlatformAccount::ChargeCustomerUsBankAccount.run(charge_params)
    end

    around do |example|
      ClimateControl.modify(STRIPE_SECRET_KEY: 'test_acc_1') do
        example.run
      end
    end

    before { StripeMock.start }
    after { StripeMock.stop }

    let(:stripe_helper) { StripeMock.create_test_helper }

    let(:account_id) { 'test_acc_1' }
    let(:customer_id) { 'test_cus_1' }
    let(:payment_method) do
      create(:payment_method, type: 'PaymentMethods::BankAccount', payment_processor_customer_id: 'test_cus_1')
    end

    before do
      Payments::CreateCustomer.run
      Payments::UpdateCustomerPaymentSource.run(
        customer_id: 'test_cus_1',
        payment_token: stripe_helper.generate_bank_token(bank_account_params)
      )
    end

    context 'when account ID, currency, donation amount and payment method are supplied' do
      context 'and the Stripe response is successful' do
        it { is_expected.to be_success }

        it 'has the correct amount and application_fee_amount' do
          expect(subject.result.receipt.amount).to eq(123) # donation_amount_cents + tips_cents
          expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
        end
      end

      context 'and the Stripe response is unsuccessful' do
        before do
          stripe_error = Stripe::StripeError.new('Some error message')
          StripeMock.prepare_error(stripe_error, :new_charge)
        end

        it 'fails with errors' do
          expect(subject).not_to be_success
          expect(subject.errors.symbolic).to include(customer: :stripe_error)
        end
      end
    end

    context 'when account ID, currency, donation amount and payment method are not supplied' do
      let(:account_id) { '' }
      let(:currency) { '' }
      let(:donation_amount_cents) { nil }
      let(:payment_method) { nil }

      it 'fails with errors' do
        expect(subject).not_to be_success
        expect(subject.errors.symbolic).to include(account_id: :empty)
        expect(subject.errors.symbolic).to include(currency: :empty)
        expect(subject.errors.symbolic).to include(donation_amount_cents: :nils)
        expect(subject.errors.symbolic).to include(payment_method: :nils)
      end
    end
  end

  # Tests tagged 'live' are not run unless you use the `rspec -t live` flag, or specify the line number.
  describe "tests using Stripe's live test server", live: true do
    let(:account_id) { ENV.fetch('STRIPE_TEST_US_ACCOUNT_ID') }

    context 'when the customer and payment source are located on the platform Stripe account' do # Legacy payment methods
      # Since it is difficult to programmatically create the right kind of test payment source on Stripe's test server
      # we use an existing test payment source. This was created using a local-development app of Donational with
      # Plaid's sandbox.
      # https://dashboard.stripe.com/test/customers/cus_PUMZQvc4bEg8iT
      let(:customer_id) { 'cus_PUMZQvc4bEg8iT' }
      let(:payment_method) do
        create(:us_bank_account_payment_method, payment_processor_customer_id: customer_id,
                                                payment_processor_source_id: 'ba_1OfNobFfEyMzV1ZsFZpPoseJ')
      end

      it "can debit the donor's account more than once" do
        first_charge_result, first_charge = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                       account_id:)
        expect(first_charge_result).to be_success
        expect(first_charge.status).to eq('succeeded')
        expect(first_charge.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
        expect(first_charge.refresh.metadata[:contribution_id]).to eq('345')

        second_charge_result, second_charge = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                         account_id:)
        expect(second_charge_result).to be_success
        expect(second_charge.status).to eq('succeeded')
        expect(second_charge.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents

        # Ensure that we tested different charges each time
        expect(first_charge.id).not_to eq(second_charge.id)
      end
    end
  end

  def make_test_payment_using_stripe_test_server(charge_params:, account_id:)
    start_time = Time.now
    charge_result = Payments::PlatformAccount::ChargeCustomerUsBankAccount.run(charge_params)
    # Wait enough time for the status on Stripe's end to become 'succeeded' if it's going to.
    timeout = 30 # seconds
    interval = 5 # seconds
    charge = nil

    loop do
      charge = Stripe::Charge.list({ created: { gte: start_time.to_i } },
                                   { stripe_account: account_id }).data.first
      break if charge.status == 'succeeded' || Time.now - start_time > timeout

      sleep interval
    end

    [charge_result, charge]
  end

  def with_modified_env(options, &)
    ClimateControl.modify(options, &)
  end
end
