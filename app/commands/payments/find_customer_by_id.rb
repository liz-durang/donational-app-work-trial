require 'panda_pay'

module Payments
  class FindCustomerById < Mutations::Command
    required do
      string :customer_id
    end

    def execute
      customer_json = pandapay_customers[customer_id].get.body
      JSON.parse(customer_json, symbolize_names: true)
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
