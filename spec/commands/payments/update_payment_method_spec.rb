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

  let(:card_params) do
    {
      number: '4242424242424242',
      exp_month: 12,
      exp_year: 1.year.from_now.year,
      cvc: '999'
    }
  end

  context 'when the donor can be found by customer id' do
    let(:payment_token) { stripe_helper.generate_card_token(card_params) }
    let(:customer_id) { 'test_cus_1' }

    before do
      Payments::CreateCustomer.run
      donor.payment_methods.create(payment_processor_customer_id: customer_id)
    end

    context "and the update to the customer's card succeeds" do
      it 'updates the card for the existing customer' do
        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_token: payment_token
        )
        expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)
        expect(command).to be_success
        expect(Payments::GetActivePaymentMethod.call(donor: donor).last4).to eq '4242'
      end
    end

    context "and the update to the customer's card fails" do
      it 'fails with the errors from the update command' do
        stripe_error = Stripe::StripeError.new('Some error message')
        StripeMock.prepare_error(stripe_error, :update_customer)

        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_token: payment_token
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :payment_error)
      end
    end
  end

  context 'when the donor does not have a customer id' do
    let(:payment_token) { stripe_helper.generate_card_token(card_params) }
    let(:customer_id) { '' }

    context 'and the customer can be created' do
      it 'saves the newly created customer id to the donor' do
        command = Payments::UpdatePaymentMethod.run(
          donor: donor,
          payment_token: payment_token
        )
        expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)

        expect(command).to be_success
        expect(Payments::GetActivePaymentMethod.call(donor: donor).payment_processor_customer_id).to include 'test_cus_'
      end

      context "and the update to the customer's card succeeds" do
        it 'updates the card for the existing customer' do
          command = Payments::UpdatePaymentMethod.run(
            donor: donor,
            payment_token: payment_token
          )
          expect(TriggerPaymentMethodUpdatedWebhook.jobs.size).to eq(1)

          expect(command).to be_success
          expect(Payments::GetActivePaymentMethod.call(donor: donor).last4).to eq '4242'
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
    let(:payment_token) { '' }
    let(:customer_id) { 'cus_123' }

    it 'fails with errors' do
      expect(Payments::FindCustomerById).not_to receive(:run)
      expect(Payments::CreateCustomer).not_to receive(:run)

      command = Payments::UpdatePaymentMethod.run(
        donor: donor,
        payment_token: payment_token
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_token: :empty)
    end
  end
end
