module Payments
  class GeneratePlaidLinkToken < ApplicationQuery
    def call(donor_id:)
      plaid_client.
        link_token.
        create(
          user: {
            client_user_id: donor_id
          },
          client_name: 'Donational',
          products: ['auth'],
          country_codes: ['US'],
          language: 'en',
        ).
        link_token
    end

    private

    def plaid_client
      @client ||= Plaid::Client.new(
        env: ENV.fetch('PLAID_ENV'),
        client_id: ENV.fetch('PLAID_CLIENT_ID'),
        secret: ENV.fetch('PLAID_SECRET'),
      )
    end

  end
end
