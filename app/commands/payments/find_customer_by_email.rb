require 'panda_pay'

module Payments
  class FindCustomerByEmail < ApplicationCommand
    required do
      string :email
    end

    def execute
      customers_json = pandapay_customers_by_email.get.body
      customers = JSON.parse(customers_json, symbolize_names: true)[:data]

      add_error(:customer, :not_found, 'Customer not found') if customers.empty?

      customers.first
    rescue RestClient::ExceptionWithResponse => e
      PandaPay.errors_from_response(e.response.body).each do |error|
        add_error(:customer, error[:type].to_sym, error[:message])
      end

      nil
    end

    private

    def pandapay_customers_by_email
      RestClient::Resource.new(
        "https://api.pandapay.io/v1/customers?email=#{email}",
        ENV.fetch('PANDAPAY_SECRET_KEY')
      )
    end
  end
end
