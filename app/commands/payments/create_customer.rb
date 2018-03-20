require 'panda_pay'

module Payments
  class CreateCustomer < ApplicationCommand
    required do
      string :email, empty: false
    end

    def execute
      response = pandapay_customers.post(email: email)

      JSON.parse(response.body, symbolize_names: true)
    rescue RestClient::ExceptionWithResponse => e
      PandaPay.errors_from_response(e.response.body).each do |error|
        add_error(:customer, error[:type].to_sym, error[:message])
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
