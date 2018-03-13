require 'panda_pay'

module Payments
  class ChargeCustomer < Mutations::Command
    SENSITIVE_PARAMETERS = %i(payment_token)

    required do
      string :customer_id, empty: false
      string :email, empty: false
      integer :amount_cents
      integer :platform_fee_cents
    end

    def execute
      payment = pandapay_donations.post(
        source: customer_id,
        amount: amount_cents,
        platform_fee: platform_fee_cents,
        currency: 'usd',
        receipt_email: email
      )

      JSON.parse(payment.body, symbolize_names: true).except(*SENSITIVE_PARAMETERS)
    rescue RestClient::ExceptionWithResponse => e
      PandaPay.errors_from_response(e.response.body).each do |error|
        add_error(:customer, error[:type].to_sym, error[:message])
      end

      nil
    end

    private

    def pandapay_donations
      RestClient::Resource.new(
        'https://api.pandapay.io/v1/donations',
        ENV.fetch('PANDAPAY_SECRET_KEY')
      )
    end
  end
end
