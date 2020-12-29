require 'rails_helper'

RSpec.describe Payments::GeneratePlaidLinkToken do
  let(:donor) { Donor.create! }

  before do
    WebMock.disable_net_connect!

    stub_request(:post, "https://#{ENV['PLAID_ENV']}.plaid.com/link/token/create")
      .with(
        body: JSON.generate({
          user: {
            client_user_id: donor.id
          },
          client_name: "Donational",
          products: ["auth"],
          country_codes:["US"],
          language: "en",
          webhook: nil,
          access_token: nil,
          link_customization_name: nil,
          redirect_uri: nil,
          android_package_name: nil,
          account_filters: nil,
          cross_app_item_add: nil,
          payment_initiation: nil,
          client_id: ENV.fetch('PLAID_CLIENT_ID'),
          secret: ENV.fetch('PLAID_SECRET')
        })
      )
      .to_return(
        status: 200,
        body: JSON.generate({
                  expiration: "2020-12-01T15:09:27Z",
                  link_token: "link-sandbox-b0c634e2-122a-4487-a2cb-dc096af3b456",
                  request_id: "FPOsDsMD7xnFOSt"
              }),
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end

  after { WebMock.allow_net_connect! }

  it "generates a result containing a link token" do
    link_token = Payments::GeneratePlaidLinkToken.call(donor_id: donor.id)
    expect(link_token).to eq('link-sandbox-b0c634e2-122a-4487-a2cb-dc096af3b456')
  end

end
