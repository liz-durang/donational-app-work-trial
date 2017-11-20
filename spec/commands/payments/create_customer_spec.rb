require 'rails_helper'

RSpec.describe Payments::CreateCustomer do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  context 'when a tokenized credit card and an email are supplied' do
    let(:payment_token) { 'tokenized_credit_card' }
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
          .with(email: 'user@example.com', source: 'tokenized_credit_card')
          .and_return(successful_response)

        outcome = Payments::CreateCustomer.run(payment_token: payment_token, email: email)

        expect(outcome).to be_success
        expect(outcome.result).to eq('cus_123')
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
        outcome = Payments::CreateCustomer.run(payment_token: payment_token, email: email)

        expect(outcome).not_to be_success
        expect(outcome.errors.symbolic).to include(donor: :some_pandapay_error_type)
      end
    end
  end

  context 'when the source and email are not supplied' do
    let(:payment_token) { '' }
    let(:email) { '' }

    it 'fails with errors' do
      outcome = Payments::CreateCustomer.run(payment_token: payment_token, email: email)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(payment_token: :empty)
      expect(outcome.errors.symbolic).to include(email: :empty)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
