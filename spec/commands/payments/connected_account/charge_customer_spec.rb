require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::ConnectedAccount::ChargeCustomer do
  let(:tips_cents) { 23 }
  let(:platform_fee_cents) { 2 }
  let(:metadata) { { 'donor_id' => '123', 'portfolio_id' => '234', 'contribution_id' => '345' } }
  let(:charge_params) do
    {
      account_id:,
      currency:,
      donation_amount_cents:,
      metadata:,
      payment_method:,
      tips_cents:,
      platform_fee_cents:
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

  describe "tests NOT using Stripe's live test server" do
    subject do
      Payments::ConnectedAccount::ChargeCustomer.run(charge_params)
    end

    around do |example|
      ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
        example.run
      end
    end

    before { StripeMock.start }
    after { StripeMock.stop }

    let(:stripe_helper) { StripeMock.create_test_helper }

    let(:account_id) { 'test_acc_1' }
    let(:currency) { 'usd' }
    let(:donation_amount_cents) { 10_000 }
    let(:customer) do
      Stripe::Customer.create({}, { stripe_account: account_id })
    end
    let(:stripe_payment_method) do
      # StripeMock only allows payment methods with type card, ideal, or sepa_debit
      Stripe::PaymentMethod.create({ type: 'card', card: card_params }, { stripe_account: account_id })
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

    context 'when the payment method is card' do
      let(:currency) { 'aud' }
      let(:payment_method) do
        create(:payment_method, type: 'PaymentMethods::Card', payment_processor_customer_id: customer.id,
                                payment_processor_source_id: stripe_payment_method[:id])
      end

      context 'when the account ID, currency, donation amount and payment method are supplied' do
        context 'and the Stripe response is successful' do
          it { is_expected.to be_success }

          it 'uses the correct payment method type in the API call' do
            expect(Stripe::PaymentIntent).to receive(:create).with(
              {
                amount: donation_amount_cents + tips_cents,
                application_fee_amount: platform_fee_cents + tips_cents,
                confirm: true,
                currency:,
                expand: ['charges.data.balance_transaction'],
                metadata:,
                payment_method: payment_method.payment_processor_source_id,
                customer: payment_method.payment_processor_customer_id,
                payment_method_types: ['card'],
                off_session: true,
                mandate: nil
              },
              stripe_account: account_id
            )

            expect(subject).to be_success
            expect(subject.result.receipt.amount).to eq(10_023) # donation_amount_cents + tips_cents
            expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
            expect(subject.result.payment_processor_fees_cents).to eq(20)
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
    end

    context 'when the payment method is (US) bank account' do
      let(:currency) { 'usd' }
      let(:payment_method) do
        create(:us_bank_account_payment_method,
               payment_processor_customer_id: customer.id, payment_processor_source_id: stripe_payment_method[:id])
      end

      context 'when the account ID, currency, donation amount and payment method are supplied' do
        context 'and the Stripe response is successful' do
          it { is_expected.to be_success }

          it 'uses the correct payment method type in the API call' do
            expect(Stripe::PaymentIntent).to receive(:create).with(
              {
                amount: donation_amount_cents + tips_cents,
                application_fee_amount: platform_fee_cents + tips_cents,
                confirm: true,
                currency:,
                expand: ['charges.data.balance_transaction'],
                metadata:,
                payment_method: payment_method.payment_processor_source_id,
                customer: payment_method.payment_processor_customer_id,
                payment_method_types: ['us_bank_account'],
                off_session: true,
                mandate: nil
              },
              stripe_account: account_id
            )

            expect(subject).to be_success
            expect(subject.result.receipt.amount).to eq(10_023) # donation_amount_cents + tips_cents
            expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
            expect(subject.result.payment_processor_fees_cents).to eq(20)
          end
        end
      end
    end

    context 'when the payment method is ACSS direct debit' do
      let(:currency) { 'cad' }
      let(:payment_method) do
        create(:acss_debit_payment_method,
               payment_processor_customer_id: customer.id, payment_processor_source_id: stripe_payment_method[:id])
      end

      context 'when the account ID, currency, donation amount and payment method are supplied' do
        context 'and the mandate cannot be found' do
          it 'fails with errors' do
            result = Payments::ConnectedAccount::ChargeCustomer.run(
              account_id:,
              currency:,
              donation_amount_cents:,
              payment_method:,
              tips_cents: 23,
              platform_fee_cents: 2
            )

            expect(result).not_to be_success
            expect(result.errors.symbolic).to include(customer: :stripe_error)
            expect(result.errors.message['customer']).to eq('Stripe mandate not found')
          end
        end

        context 'and the mandate is present' do
          before do
            allow(Stripe::SetupIntent).to receive(:list).with(
              { customer: customer.id, payment_method: stripe_payment_method[:id] },
              { stripe_account: account_id }
            ).and_return(
              double(data: [double(mandate: 'mandate_123')])
            )
          end

          context 'and the Stripe response is successful' do
            it { is_expected.to be_success }

            it 'uses the correct payment method type and provides a mandate id in the API call' do
              expect(Stripe::PaymentIntent).to receive(:create).with(
                {
                  amount: donation_amount_cents + tips_cents,
                  application_fee_amount: platform_fee_cents + tips_cents,
                  confirm: true,
                  currency:,
                  expand: ['charges.data.balance_transaction'],
                  metadata:,
                  payment_method: payment_method.payment_processor_source_id,
                  customer: payment_method.payment_processor_customer_id,
                  payment_method_types: ['acss_debit'],
                  off_session: true,
                  mandate: 'mandate_123'
                },
                stripe_account: account_id
              )

              expect(subject).to be_success
              expect(subject.result.receipt.amount).to eq(10_023) # donation_amount_cents + tips_cents
              expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
              expect(subject.result.payment_processor_fees_cents).to eq(140)
            end

            context 'but the currency is invalid' do
              it 'fails with errors' do
                result = Payments::ConnectedAccount::ChargeCustomer.run(
                  account_id:,
                  currency: 'gbp',
                  donation_amount_cents:,
                  metadata:,
                  payment_method:,
                  tips_cents: 23,
                  platform_fee_cents: 2
                )

                expect(result).not_to be_success
                expect(result.errors.symbolic).to include(customer: :payment_error)
              end
            end
          end
        end
      end
    end

    context 'when the payment method is BACS direct debit' do
      let(:currency) { 'gbp' }
      let(:payment_method) do
        create(:bacs_debit_payment_method,
               payment_processor_customer_id: customer.id, payment_processor_source_id: stripe_payment_method[:id])
      end

      context 'when the account ID, currency, donation amount and payment method are supplied' do
        context 'and the mandate cannot be found' do
          it 'fails with errors' do
            result = Payments::ConnectedAccount::ChargeCustomer.run(
              account_id:,
              currency:,
              donation_amount_cents:,
              payment_method:,
              tips_cents: 23,
              platform_fee_cents: 2
            )

            expect(result).not_to be_success
            expect(result.errors.symbolic).to include(customer: :stripe_error)
            expect(result.errors.message['customer']).to eq('Stripe mandate not found')
          end
        end

        context 'and the mandate is present' do
          before do
            allow(Stripe::SetupIntent).to receive(:list).with(
              { customer: customer.id, payment_method: stripe_payment_method[:id] },
              { stripe_account: account_id }
            ).and_return(
              double(data: [double(mandate: 'mandate_123')])
            )
          end

          context 'and the Stripe response is successful' do
            it { is_expected.to be_success }

            it 'uses the correct payment method type and provides a mandate id in the API call' do
              expect(Stripe::PaymentIntent).to receive(:create).with(
                {
                  amount: donation_amount_cents + tips_cents,
                  application_fee_amount: platform_fee_cents + tips_cents,
                  confirm: true,
                  currency:,
                  expand: ['charges.data.balance_transaction'],
                  metadata:,
                  payment_method: payment_method.payment_processor_source_id,
                  customer: payment_method.payment_processor_customer_id,
                  payment_method_types: ['bacs_debit'],
                  off_session: true,
                  mandate: 'mandate_123'
                },
                stripe_account: account_id
              )

              expect(subject).to be_success
              expect(subject.result.receipt.amount).to eq(10_023) # donation_amount_cents + tips_cents
              expect(subject.result.receipt.application_fee_amount).to eq(25) # platform_fee_cents + tips_cents
              expect(subject.result.payment_processor_fees_cents).to eq(120)
            end

            context 'but the currency is invalid' do
              it 'fails with errors' do
                result = Payments::ConnectedAccount::ChargeCustomer.run(
                  account_id:,
                  currency: 'cad',
                  donation_amount_cents:,
                  metadata:,
                  payment_method:,
                  tips_cents: 23,
                  platform_fee_cents: 2
                )

                expect(result).not_to be_success
                expect(result.errors.symbolic).to include(customer: :payment_error)
              end
            end
          end
        end
      end
    end
  end

  # Tests tagged 'live' are not run unless you use the `rspec -t live` flag, or specify the line number.
  describe "tests using Stripe's live test server", live: true do
    let(:currency) { 'usd' }
    let(:donation_amount_cents) { 100 }

    context 'and the customer and payment method are located on a connected Stripe account' do
      let(:customer) { Stripe::Customer.create({}, { stripe_account: account_id }) }

      context 'when the payment method type is card' do
        let(:account_id) { ENV.fetch('STRIPE_TEST_UK_ACCOUNT_ID') }
        let(:payment_method) do
          create(:payment_method, type: 'PaymentMethods::Card', payment_processor_customer_id: customer.id,
                                  payment_processor_source_id: stripe_payment_method[:id])
        end
        let(:stripe_payment_method) do
          Stripe::PaymentMethod.create({ type: 'card', card: card_params },
                                       { stripe_account: account_id })
        end

        before do
          Stripe::PaymentMethod.attach(stripe_payment_method[:id], { customer: customer.id },
                                       { stripe_account: account_id })
        end

        after do
          Stripe::Customer.delete(customer.id, {}, { stripe_account: account_id })
        end

        it "can debit the donor's account more than once" do
          # TODO: ensure this test fails if I hard-code the incorrect payment method types into the call to create a payment intent
          expect(it_can_debit_the_donors_account_more_than_once(charge_params:,
                                                                account_id:)).to be(true)
        end
      end

      context 'when the payment method type is (US) bank account' do
        # Since it is difficult to programmatically create the right kind of test payment source on Stripe's test server
        # (we cannot verify the payment method via API) we use an existing test payment source.
        # This was created using a local-development app of Donational with Stripe's test server.
        # https://dashboard.stripe.com/test/connect/accounts/acct_1CvDY9FqsmEov1GT/customers/cus_PX5JAjn8CHFj7d
        let(:account_id) { ENV.fetch('STRIPE_TEST_US_ACCOUNT_ID') }
        let(:payment_method) do
          create(:us_bank_account_payment_method, payment_processor_customer_id: 'cus_PX5JAjn8CHFj7d',
                                                  payment_processor_source_id: 'pm_1Oi19IFqsmEov1GTgBQn9f9i')
        end

        it "can debit the donor's account more than once" do
          expect(it_can_debit_the_donors_account_more_than_once(charge_params:,
                                                                account_id:)).to be(true)
        end
      end

      context 'when the payment method type is ACSS debit' do
        # Since it is difficult to programmatically create the right kind of test payment source on Stripe's test server
        # (we cannot verify the payment method via API) we use an existing test payment source.
        # This was created using a local-development app of Donational with Stripe's test server.
        # https://dashboard.stripe.com/test/connect/accounts/acct_1CvDY9FqsmEov1GT/customers/cus_PX5JAjn8CHFj7d
        let(:account_id) { ENV.fetch('STRIPE_TEST_CAN_ACCOUNT_ID') }
        let(:payment_method) do
          create(:acss_debit_payment_method, payment_processor_customer_id: 'cus_PSsL346buqY9GM',
                                             payment_processor_source_id: 'pm_1OdwaJKbbzG9NV80Xc4oKVZa')
        end
        let(:currency) { 'cad' }

        it "can debit the donor's account more than once" do
          expect(it_can_debit_the_donors_account_more_than_once(charge_params:,
                                                                account_id:)).to be(true)
        end
      end

      context 'when the payment method type is BACS debit' do
        # Since it is difficult to programmatically create the right kind of test payment source on Stripe's test server
        # (we cannot verify the payment method via API) we use an existing test payment source.
        # This was created using a local-development app of Donational with Stripe's test server.
        # https://dashboard.stripe.com/test/connect/accounts/acct_1MtvX2HiYkbln5dM/customers/cus_PX5ZdM8fcVTx8E
        let(:account_id) { ENV.fetch('STRIPE_TEST_UK_ACCOUNT_ID') }

        let(:payment_method) do
          create(:bacs_debit_payment_method, payment_processor_customer_id: 'cus_PX5ZdM8fcVTx8E',
                                             payment_processor_source_id: 'pm_1Oi1OPHiYkbln5dMI9y7qKFn')
        end
        let(:currency) { 'gbp' }

        it "can debit the donor's account more than once" do
          expect(it_can_debit_the_donors_account_more_than_once(charge_params:,
                                                                account_id:)).to be(true)
        end
      end
    end
  end

  # Trying to debit twice gives more confidence, because there are some conditions under which payment methods are
  # 'consumed'. https://stripe.com/docs/payments/payment-methods/connect#cloning-payment-methods
  def it_can_debit_the_donors_account_more_than_once(charge_params:, account_id:)
    first_charge_result, first_payment_intent = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                           account_id:)
    expect(first_charge_result).to be_success
    expect(first_payment_intent.status).to eq('succeeded')
    expect(first_payment_intent.metadata[:contribution_id]).to eq('345')

    second_charge_result, second_payment_intent = make_test_payment_using_stripe_test_server(charge_params:,
                                                                                             account_id:)
    expect(second_charge_result).to be_success
    expect(second_payment_intent.status).to eq('succeeded')

    # Ensure that we tested different payment intents each time
    expect(first_payment_intent.id).not_to eq(second_payment_intent.id)
  end

  def make_test_payment_using_stripe_test_server(charge_params:, account_id:)
    start_time = Time.now
    charge_result = Payments::ConnectedAccount::ChargeCustomer.run(charge_params)
    # Wait enough time for the status on Stripe's end to become 'succeeded' if it's going to.
    timeout = 30 # seconds
    interval = 5 # seconds
    payment_intent = nil

    loop do
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
