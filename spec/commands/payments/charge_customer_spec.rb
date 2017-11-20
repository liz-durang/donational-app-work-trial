require 'rails_helper'

RSpec.describe Payments::ChargeCustomer do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  context 'when the customer id and receipt email are supplied' do
    let(:customer_id) { 'cus_123' }
    let(:email) { 'user@example.com' }
    let(:donations_resource) { instance_double(RestClient::Resource) }

    before do
      allow(RestClient::Resource)
        .to receive(:new)
        .with('https://api.pandapay.io/v1/donations', 'sk_test_123')
        .and_return(donations_resource)
    end

    context 'and the pandapay response is successful' do
      let(:successful_response) { double(:successful_response, body: '{ "some": "json_receipt" }') }

      it "charges the donor's credit card with Payments" do
        expect(donations_resource)
          .to receive(:post)
          .with(
            receipt_email: 'user@example.com',
            source: 'cus_123',
            amount: 123,
            platform_fee: 0,
            currency: 'usd'
          ).and_return(successful_response)

        command = Payments::ChargeCustomer.run(
          customer_id: customer_id,
          email: email,
          amount_cents: 123
        )

        expect(command).to be_success
        expect(command.result).to eq({ some: 'json_receipt' })
      end

      it "filters out sensitive data (ie payment_token) from the receipt" do
        unfiltered_json = '{ "payment_token": "this_is_sensitive", "id": 123 }'
        expect(donations_resource).to receive(:post).and_return(double(body: unfiltered_json))

        command = Payments::ChargeCustomer.run(customer_id: customer_id, email: email, amount_cents: 123)

        expect(command.result.keys).not_to include('payment_token')
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
        allow(donations_resource)
          .to receive(:post)
          .and_raise(RestClient::ExceptionWithResponse.new(unsuccessful_response))
      end

      it 'fails with errors' do
        command = Payments::ChargeCustomer.run(customer_id: customer_id, email: email, amount_cents: 123)

        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(customer: :some_pandapay_error_type)
      end
    end
  end

  context 'when the customer_id and email are not supplied' do
    let(:customer_id) { '' }
    let(:email) { '' }

    it 'fails with errors' do
      command = Payments::ChargeCustomer.run(customer_id: customer_id, email: email, amount_cents: 123)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(customer_id: :empty)
      expect(command.errors.symbolic).to include(email: :empty)
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
