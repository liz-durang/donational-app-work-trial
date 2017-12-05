require 'rails_helper'

RSpec.describe Payments::FindCustomerByEmail do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:email) { 'user@example.com' }
  let(:customers_resource) { instance_double(RestClient::Resource) }

  before do
    allow(RestClient::Resource)
      .to receive(:new)
      .with('https://api.pandapay.io/v1/customers?email=user@example.com', 'sk_test_123')
      .and_return(customers_resource)
  end


  context 'when the pandapay response is successful' do
    context 'and there is a customer matching the email' do
      let(:customers_response) do
        double(
          body: '{ "data": [{ "id": "cus_123", "object": "customer", "email": "user@example.com" }] }'
        )
      end
      before do
        expect(customers_resource)
          .to receive(:get)
          .and_return(customers_response)
      end

      it 'returns the customer' do
        command = Payments::FindCustomerByEmail.run(email: email)

        expect(command).to be_success
        expect(command.result).to eq({ id: 'cus_123', object: 'customer', email: 'user@example.com' })
      end
    end

    context 'and there is no matching customer' do
      before do
        expect(customers_resource)
          .to receive(:get)
          .and_return(double(body: '{ "data": [] }'))
      end

      it 'fails with a customer not found error' do
        command = Payments::FindCustomerByEmail.run(email: email)

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :not_found)
      end
    end
  end

  context 'when the pandapay response is unsuccessful' do
    let(:unsuccessful_response) do
      double(
        :unsuccessful_response,
        body: %q({"errors":[{"type":"some_pandapay_error_type","message":"Some message"}]})
      )
    end

    before do
      expect(customers_resource)
        .to receive(:get)
        .and_raise(RestClient::ExceptionWithResponse.new(unsuccessful_response))
    end

    it 'fails with errors' do
      command = Payments::FindCustomerByEmail.run(email: email)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer: :some_pandapay_error_type)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
