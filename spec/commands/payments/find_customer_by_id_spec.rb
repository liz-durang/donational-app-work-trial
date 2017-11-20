require 'rails_helper'

RSpec.describe Payments::FindCustomerById do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:customer_id) { 'cus_123' }
  let(:customers_resource) { instance_double(RestClient::Resource) }
  let(:customer_resource) { instance_double(RestClient::Resource) }

  before do
    allow(RestClient::Resource)
      .to receive(:new)
      .with('https://api.pandapay.io/v1/customers', 'sk_test_123')
      .and_return(customers_resource)
  end

  context 'when the pandapay response is successful' do
    let(:customer_response) do
      double(body: '{ "id": "cus_123", "object": "customer", "email": "user@example.com" }')
    end

    before do
      expect(customers_resource)
        .to receive(:[])
        .with(customer_id)
        .and_return(customer_resource)
      expect(customer_resource)
        .to receive(:get)
        .and_return(customer_response)
    end

    it 'returns the customer' do
      command = Payments::FindCustomerById.run(customer_id: customer_id)

      expect(command).to be_success
      expect(command.result).to eq({ id: 'cus_123', object: 'customer', email: 'user@example.com' })
    end
  end

  context 'when the pandapay response is unsuccessful' do
    let(:unsuccessful_response) do
      double(
        :unsuccessful_response,
        body: %q({"error":{"type":"some_pandapay_error_type","message":"Some message"}})
      )
    end

    before do
      expect(customers_resource)
        .to receive(:[])
        .with(customer_id)
        .and_return(customer_resource)
      expect(customer_resource)
        .to receive(:get)
        .and_raise(RestClient::ExceptionWithResponse.new(unsuccessful_response))
    end

    it 'fails with errors' do
      command = Payments::FindCustomerById.run(customer_id: customer_id)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :some_pandapay_error_type)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
