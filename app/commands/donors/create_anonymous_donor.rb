module Donors
  class CreateAnonymousDonor < ApplicationCommand
    optional do
      string :donor_id
      string :partner_id
      model :campaign
    end

    def execute
      donor = Donor.new(id: donor_id)
      donor.save!

      Partners::AffiliateDonorWithPartner.run(donor: donor, partner: partner, campaign: campaign)

      donor
    end

    private

    def partner
      Partner.find_by(id: partner_id) || Partner.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
