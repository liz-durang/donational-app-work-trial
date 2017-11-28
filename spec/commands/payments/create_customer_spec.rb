require 'rails_helper'

RSpec.describe Payments::CreateCustomer do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  context 'when an email is supplied' do
    let(:email) { 'user@example.com' }
    let(:customers_resource) { instance_double(RestClient::Resource) }

    before do
      allow(RestClient::Resource)
        .to receive(:new)
        .with('https://api.pandapay.io/v1/customers', 'sk_test_123')
        .and_return(customers_resource)
    end

    context 'and the pandapay response is successful' do
      let(:successful_response) { double(:successful_response, body: customer_json_response) }
      let(:customer_json_response) do
        '{ "id": "cus_123", "object": "customer", "foo": "bar" }'
      end

      it "returns the id of a newly created customer" do
        expect(customers_resource)
          .to receive(:post)
          .with(email: 'user@example.com')
          .and_return(successful_response)

        command = Payments::CreateCustomer.run(email: email)

        expect(command).to be_success
        expect(command.result).to eq({ id: "cus_123", object: "customer", foo: "bar" })
      end
    end

    context 'and the pandapay response is unsuccessful' do
      let(:unsuccessful_response) do
        double(
          :unsuccessful_response,
          body: %q({"errors":[{"type":"some_pandapay_error_type","message":"Some message"}]})
        )
      end

      before do
        allow(customers_resource)
          .to receive(:post)
          .and_raise(RestClient::ExceptionWithResponse.new(unsuccessful_response))
      end

      it 'fails with errors' do
        command = Payments::CreateCustomer.run(email: email)

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :some_pandapay_error_type)
      end
    end
  end

  context 'when the email is not supplied' do
    let(:email) { '' }

    it 'fails with errors' do
      command = Payments::CreateCustomer.run(email: email)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(email: :empty)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
