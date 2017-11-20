require 'panda_pay'

module Payments
  class UpdateCustomerCard < Mutations::Command
    required do
      string :customer_id
      string :payment_token
    end

    def execute
      card_json = pandapay_customers["#{customer_id}/cards"].post(source: payment_token).body

      JSON.parse(card_json, symbolize_names: true)
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
