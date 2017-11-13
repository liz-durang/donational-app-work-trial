module Payments
  class ChargeCustomer < Mutations::Command
    SENSITIVE_PARAMETERS = %w(payment_token)
    PLATFORM_FEE = 0

    required do
      string :customer_id, empty: false
      string :email, empty: false
      integer :amount_cents
    end

    def execute
      payment = pandapay_donations.post(
        source: customer_id,
        amount: amount_cents,
        platform_fee: platform_fee,
        currency: 'usd',
        receipt_email: email
      )

      JSON.parse(payment.body).except(*SENSITIVE_PARAMETERS)
    rescue RestClient::ExceptionWithResponse => e
      JSON.parse(e.response.body)['errors'].each do |error|
        add_error(:donor, error['type'].to_sym, error['message'])
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

    def platform_fee
      PLATFORM_FEE
    end
  end
end
