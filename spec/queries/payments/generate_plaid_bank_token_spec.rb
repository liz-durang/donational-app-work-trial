require 'rails_helper'

RSpec.describe Payments::GeneratePlaidBankToken do
  before do
    WebMock.disable_net_connect!

    stub_request(:post, "https://#{ENV['PLAID_ENV']}.plaid.com/item/public_token/exchange")
      .with(
        body: JSON.generate(
          public_token: 'pubrick',
          client_id: ENV.fetch('PLAID_CLIENT_ID'),
          secret: ENV.fetch('PLAID_SECRET')
        )
      )
      .to_return(
        status: 200,
        body: JSON.generate(
          access_token: 'qwerty'
        ),
        headers: {
          'Content-Type'=>'application/json'
        }
      )

    stub_request(:post, "https://#{ENV['PLAID_ENV']}.plaid.com/processor/stripe/bank_account_token/create")
      .with(
        body: JSON.generate(
          access_token: 'qwerty',
          account_id: '123456',
          client_id: ENV.fetch('PLAID_CLIENT_ID'),
          secret: ENV.fetch('PLAID_SECRET'),
        ),
      )
      .to_return(
        status: 200,
        body: JSON.generate(
          stripe_bank_account_token: 'banker-token'
        ),
        headers: {
          'Content-Type' => 'application/json'
        }
      )
  end

  after { WebMock.allow_net_connect! }

  it 'generates a bank token from an initial public token and account_id' do
    bank_token = Payments::GeneratePlaidBankToken.new.call(
      public_token: 'pubrick',
      account_id: '123456'
    )
    expect(bank_token).to eq 'banker-token'
  end
end


