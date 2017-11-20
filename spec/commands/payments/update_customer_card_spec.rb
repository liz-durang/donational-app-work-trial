require 'rails_helper'

RSpec.describe Payments::UpdateCustomerCard do
  let(:customers_resource) { instance_double(RestClient::Resource) }
  let(:customer_resource) { instance_double(RestClient::Resource) }

  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  before do
    allow(RestClient::Resource)
      .to receive(:new)
      .with('https://api.pandapay.io/v1/customers', 'sk_test_123')
      .and_return(customers_resource)

    allow(customers_resource)
      .to receive(:[])
      .with('cus_123/cards')
      .and_return(customer_resource)
  end

  context 'when a card can be added to the customer' do
    let(:successful_create) do
      double(:successful_create, body: '{ "id": "card_123", "object": "card", "foo": "bar" }')
    end

    it 'updates the customer card' do
      expect(customer_resource).to receive(:post).with(source: 'foo').and_return(successful_create)

      command = Payments::UpdateCustomerCard.run(customer_id: 'cus_123', payment_token: 'foo')

      expect(command).to be_success
      expect(command.result).to eq({ id: "card_123", object: "card", foo: "bar" })
    end
  end

  context 'when a customer card cannot be created' do
    let(:failed_create) do
      double(:failed_create, body: '{ "error": { "type": "some_pandapay_error_type", "message": "some_message" } }')
    end

    before do
      expect(customer_resource)
        .to receive(:post)
        .and_raise(RestClient::ExceptionWithResponse.new(failed_create))
    end

    it 'fails with errors' do
      command = Payments::UpdateCustomerCard.run(customer_id: 'cus_123', payment_token: 'foo')

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :some_pandapay_error_type)
    end
  end
end
