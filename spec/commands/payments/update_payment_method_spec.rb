require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::UpdatePaymentMethod do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:donor) { Donor.create(email: 'donor@example.com') }

  let(:bank_account_params) do
    {
      account_holder_name: 'Donatello Donor',
      account_holder_type: 'individual',
      country: 'US',
      routing_number: '110000000',
      account_number: '000123456789'
    }
  end

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

  context 'when the donor can be found by customer id' do
    let(:customer_id) { 'test_cus_1' }
    let(:payment_method) { Payments::GetActivePaymentMethod.call(donor: donor) }
    let(:stripe_payment_method) do
      Stripe::PaymentMethod.create({ type: 'card', card: card_params, billing_details: billing_details_params })
    end

    before do
      Payments::CreateCustomer.run
      donor.payment_methods.create(payment_processor_customer_id: customer_id)
    end

    context "and the update to the customer's credit card succeeds" do
      it 'updates the credit card for the existing customer' do
        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_method_id: stripe_payment_method[:id]
        )

        expect(command).to be_success
        expect(payment_method.address_zip_code).to eq('19702')
        expect(payment_method.name).to eq('Donatello Donor')
        expect(payment_method.payment_processor_source_id).to eq(stripe_payment_method[:id])
        expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)
      end
    end

    context "and the update to the customer's credit card fails" do
      it 'fails with the errors from the update command' do
        stripe_error = Stripe::StripeError.new('Some error message')
        StripeMock.prepare_error(stripe_error, :attach_payment_method)

        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_method_id: stripe_payment_method[:id]
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :payment_error)
      end
    end
  end

  context 'when the donor does not have a customer id' do
    let(:customer_id) { '' }
    let(:payment_token) { stripe_helper.generate_bank_token(bank_account_params) }
    let(:payment_method) { Payments::GetActivePaymentMethod.call(donor: donor) }

    context 'and the customer can be created' do
      it 'saves the newly created customer id to the donor' do
        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_token: payment_token
        )

        expect(command).to be_success
        expect(payment_method.payment_processor_customer_id).to include 'test_cus_'
        expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)
      end

      context "and the update to the customer's payment source succeeds" do
        it 'updates the bank account for the existing customer' do
          command = Payments::UpdatePaymentMethod.run(
            donor: donor,
            payment_token: payment_token
          )

          expect(command).to be_success
          expect(payment_method.last4).to eq('6789')
          expect(payment_method.name).to eq('Donatello Donor')
          expect(payment_method.payment_processor_customer_id).to include 'test_cus_'
          expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)
        end
      end
    end

    context 'and the customer cannot be created' do
      let(:another_donor) { Donor.create(email: 'another_donor@example.com') }

      it 'fails with customer not found errors' do
        stripe_error = Stripe::StripeError.new('Some error message')
        StripeMock.prepare_error(stripe_error, :new_customer)

        command = Payments::UpdatePaymentMethod.run(
          donor: another_donor,
          payment_token: 'payment_token'
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :empty)
      end
    end
  end

  context 'when a payment token is not supplied' do
    let(:customer_id) { 'cus_123' }
    let(:payment_method_id) { '' }
    let(:payment_token) { '' }

    it 'fails with errors' do
      expect(Payments::FindCustomerById).not_to receive(:run)
      expect(Payments::CreateCustomer).not_to receive(:run)

      command = Payments::UpdatePaymentMethod.run(
        donor: donor,
        payment_method_id: payment_method_id,
        payment_token: payment_token
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_method: :empty)
    end
  end
end
