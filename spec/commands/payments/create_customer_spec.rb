require 'rails_helper'
require 'stripe_mock'

RSpec.describe Payments::CreateCustomer do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  before { StripeMock.start }
  after { StripeMock.stop }

  context 'without customer data' do
    context 'and the Stripe response is successful' do
      it 'returns the newly created customer' do
        command = Payments::CreateCustomer.run

        expect(command).to be_success
        expect(command.result[:id]).to eq('test_cus_1')
      end
    end

    context 'and the Stripe response is unsuccessful' do
      let(:error_message) { 'Some error message' }

      it 'fails with errors' do
        stripe_error = Stripe::StripeError.new(error_message)
        StripeMock.prepare_error(stripe_error, :new_customer)

        command = Payments::CreateCustomer.run

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :stripe_error)
      end
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
