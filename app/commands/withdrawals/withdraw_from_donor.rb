module Withdrawals
  class WithdrawFromDonor < Mutations::Command
    required do
      model :donor
      integer :amount_cents
    end

    def execute
      # donor_account_uuid = Donors::GetBankAccountUuid.call(donor: donor)
      # our_account_uuid = ENV.fetch('DWOLLA_BANK_ACCOUNT_UUID')

      # account_token = Dwolla.account_token(...)
      # request_body = {
      #   :_links => {
      #     :source => { :href => "https://api.dwolla.com/funding-sources/{donor_account_uuid}" },
      #     :destination => { :href => "https://api.dwolla.com/accounts/{our_account_uuid}" }
      #   },
      #   :amount => { :currency => "USD", :value => "225.00" },
      #   :metadata => { :foo => "bar", :baz => "boo" }
      # }
      #
      # transfer = account_token.post('transfers', request_body)
      # transfer.headers[:location] # => "https://api.dwolla.com/transfers/d76265cd-0951-e511-80da-0aa34a9b2388"
    end
  end
end
