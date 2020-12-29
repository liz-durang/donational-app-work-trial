module Payments
  class GeneratePlaidBankToken < ApplicationQuery
    def call(public_token:, account_id:)
      exchange_token_response = plaid_client
                                  .item
                                  .public_token
                                  .exchange(public_token)

      access_token = exchange_token_response['access_token']

      stripe_response = plaid_client
                          .processor
                          .stripe
                          .bank_account_token
                          .create(access_token, account_id)
      bank_account_token = stripe_response['stripe_bank_account_token']
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
