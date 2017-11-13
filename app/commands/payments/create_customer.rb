module Payments
  class CreateCustomer < Mutations::Command
    required do
      string :payment_token, empty: false
      string :email, empty: false
    end

    def execute
      payment = pandapay_customers.post(
        source: payment_token,
        email: email
      )

      JSON.parse(payment.body)['id']
    rescue RestClient::ExceptionWithResponse => e
      JSON.parse(e.response.body)['errors'].each do |error|
        add_error(:donor, error['type'].to_sym, error['message'])
      end

      nil
    end

    private

    def pandapay_customers
      RestClient::Resource.new(
        'https://api.pandapay.io/v1/customers',
        ENV.fetch('PANDAPAY_SECRET_KEY')
      )
    end
  end
end
