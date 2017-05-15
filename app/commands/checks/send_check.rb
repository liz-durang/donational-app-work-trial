module Checks
  class SendCheck < Mutations::Command
    required do
      model :organization
      integer :amount_cents
    end

    def execute
      # address = Organizations::GetOrganizationAddress.run(organization: organization)

      # @lob = Lob::Client.new(...)
      # @lob.checks.create(
      #   description: "Demo Check",
      #   bank_account: "bank_8cad8df5354d33f",
      #   to: {
      #     name: "Harry Zhang",
      #     address_line1: "123 Test Street",
      #     address_city: "Mountain View",
      #     address_state: "CA",
      #     address_country: "US",
      #     address_zip: "94041"
      #   },
      #   from: "adr_eae4448bb64c07f0",
      #   amount: 22.50,
      #   memo: "rent",
      #   logo: "https://s3-us-west-2.amazonaws.com/lob-assets/lob_check_logo.png",
      #   check_bottom: "https://s3-us-west-2.amazonaws.com/lob-assets/check-file-example.pdf"
      # )
    end
  end
end
