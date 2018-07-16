module Payments
  class ConnectPartnerAccount < ApplicationCommand
    required do
      model :partner
      string :authorization_code
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      response = Stripe::OAuth.token(
        {
          code: authorization_code,
          grant_type: 'authorization_code'
        }
      )

      chain do
        Partners::UpdatePartner.run(
          partner: partner,
          payment_processor_account_id: response.stripe_user_id
        )
      end

      nil
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:partner, :stripe_error, e.message)

      nil
    end
  end
end
