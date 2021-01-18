module Donors
  class CreateAnonymousDonor < ApplicationCommand
    optional do
      string :donor_id
    end

    def execute
      donor = Donor.new(id: donor_id)
      donor.save!

      Partners::AffiliateDonorWithPartner.run(donor: donor, partner: partner)

      donor
    end

    private

    def partner
      Partner.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
