require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::RefundCharge do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:stripe_helper) { StripeMock.create_test_helper }

  before { StripeMock.start }
  after { StripeMock.stop }

  before do
    Payments::CreateCustomer.run
  end

  context 'when the charge ID and account ID are supplied' do
    let(:charge_id) { 'test_charge_1' }
    let(:account_id) { 'test_acc_1' }
    let(:charge) do
      Stripe::Charge.create(
        amount: 100,
        currency: 'usd',
        customer: 'test_customer_1'
      )
    end

    context 'and the stripe response is successful' do
      it 'refunds the charge' do
        command = described_class.run(
          charge_id: charge.id,
          account_id:,
          application_fee_amount_cents: 100
        )

        expect(command).to be_success
      end
    end

    context 'and the charge ID is invalid' do
      let(:error_message) { 'No such charge: invalid ID' }

      it 'fails with errors' do
        stripe_error = Stripe::StripeError.new(error_message)
        command = described_class.run(
          charge_id: 'invalid ID',
          account_id:,
          application_fee_amount_cents: 100
        )

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :stripe_error)
      end
    end
  end

  context 'when the charge ID and account ID and application fee amount are not supplied' do
    let(:charge_id) { '' }
    let(:account_id) { '' }
    let(:application_fee_amount_cents) { nil }

    it 'fails with errors' do
      command = described_class.run(
        charge_id:,
        account_id:,
        application_fee_amount_cents:
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(charge_id: :empty)
      expect(command.errors.symbolic).to include(account_id: :empty)
      expect(command.errors.symbolic).to include(application_fee_amount_cents: :nils)
    end
  end

  def with_modified_env(options, &)
    ClimateControl.modify(options, &)
  end
end
