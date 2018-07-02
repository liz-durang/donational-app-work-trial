require 'rails_helper'

RSpec.describe Payments::FindCustomerById do
  around do |example|
    ClimateControl.modify(STRIPE_SECRET_KEY: 'sk_test_QaS3Ao4UjJPLuhWA86UfHNyS') do
      example.run
    end
  end

  before(:all) do
    StripeMock.start
  end

  after(:all) do
    StripeMock.stop
  end

  let(:customer_id) { 'test_cus_1' }

  before do
    Payments::CreateCustomer.run
  end

  context 'when the Stripe response is successful' do
    it 'returns the customer' do
      command = Payments::FindCustomerById.run(customer_id: customer_id)

      expect(command).to be_success
      expect(command.result[:id]).to eq(customer_id)
    end
  end

  context 'when the pandapay response is unsuccessful' do
    it 'fails with errors' do
      command = Payments::FindCustomerById.run(customer_id: 'incorrect_cus_id')

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :stripe_error)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
