require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::PlatformAccount::ChargeCustomerCard do
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

  describe "tests NOT using Stripe's live test server" do
    subject do
      Payments::PlatformAccount::ChargeCustomerCard.run(charge_params)
    end

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
    let(:donation_amount_cents) { 100 }
    let(:payment_method) do
      create(:payment_method, type: 'PaymentMethods::Card', payment_processor_customer_id: 'test_cus_1')
    end

    around do |example|
      ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
        example.run
      end
    end

    before { StripeMock.start }
    after { StripeMock.stop }

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
        it { is_expected.to be_success }

        it 'has the correct amount and application_fee_amount' do
          expect(subject.result.receipt.amount).to eq(123) # donation_amount_cents + tips_cents
          expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
        end
      end

      context 'and the Stripe response is unsuccessful' do
        before do
          stripe_error = Stripe::StripeError.new('Some error message')
          StripeMock.prepare_error(stripe_error, :new_payment_intent)
        end

        it 'fails with errors' do
          expect(subject).not_to be_success
          expect(subject.errors.symbolic).to include(customer: :stripe_error)
        end
      end
    end

    context 'when the account ID, currency, donation amount and payment method are not supplied' do
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
    let(:payment_method) do
      create(:payment_method, type: 'PaymentMethods::Card', payment_processor_customer_id: customer.id,
                              payment_processor_source_id: stripe_payment_method[:id])
    end
    let(:card_params) do
      {
        number: '4242424242424242',
        exp_month: 12,
        exp_year: 1.year.from_now.year,
        cvc: '999'
      }
    end
    let(:currency) { 'usd' }
    let(:donation_amount_cents) { 100 }
    let(:account_id) { ENV.fetch('STRIPE_TEST_UK_ACCOUNT_ID') }

    context 'and the customer and payment method are located on the platform Stripe account' do
      let(:stripe_payment_method) { Stripe::PaymentMethod.create({ type: 'card', card: card_params }) }
      let(:customer) { Payments::CreateCustomer.run.result }

      before do
        Stripe::PaymentMethod.attach(stripe_payment_method[:id], { customer: customer.id })
      end

      after do
        Stripe::Customer.delete(customer.id)
      end

      it "can debit the donor's account more than once" do
        first_charge_result, first_payment_intent = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                               account_id:)
        expect(first_charge_result).to be_success
        expect(first_payment_intent.status).to eq('succeeded')
        expect(first_payment_intent.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
        expect(first_payment_intent.refresh.metadata[:contribution_id]).to eq('345')

        second_charge_result, second_payment_intent = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                                 account_id:)
        expect(second_charge_result).to be_success
        expect(second_payment_intent.status).to eq('succeeded')
        expect(second_payment_intent.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents

        # Ensure that we tested different payment intents each time
        expect(first_payment_intent.id).not_to eq(second_payment_intent.id)
      end
    end
  end

  def make_test_payment_using_stripe_test_server(charge_params:, account_id:)
    start_time = Time.now
    charge_result = Payments::PlatformAccount::ChargeCustomerCard.run(charge_params)
    # Wait enough time for the status on Stripe's end to become 'succeeded' if it's going to.
    timeout = 30 # seconds
    interval = 5 # seconds
    payment_intent = nil

    loop do
      # Although the original payment method is on the platform account, the one we are using to charge has been
      # cloned across to the connected account, and so the PaymentIntent is also located there.
      payment_intent = Stripe::PaymentIntent.list({ created: { gte: start_time.to_i } },
                                                  { stripe_account: account_id }).data.first
      break if payment_intent.status == 'succeeded' || Time.now - start_time > timeout

      sleep interval
    end

    [charge_result, payment_intent]
  end

  def with_modified_env(options, &)
    ClimateControl.modify(options, &)
  end
end
