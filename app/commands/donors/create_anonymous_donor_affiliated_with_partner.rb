module Donors
  class CreateAnonymousDonorAffiliatedWithPartner < ApplicationCommand
    optional do
      string :donor_id
      model :partner
      model :campaign
    end

    def execute
      donor = Donor.new(id: donor_id)
      donor.save!

      Partners::AffiliateDonorWithPartner.run(
        donor: donor,
        partner: partner || default_partner,
        campaign: campaign
      )

      donor
    end

    private

    def default_partner
      Partner.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
