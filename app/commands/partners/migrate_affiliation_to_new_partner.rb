module Partners
  class MigrateAffiliationToNewPartner < ApplicationCommand
    required do
      model :partner_affiliation
      model :partner
    end

    def execute
      donor = partner_affiliation.donor
      custom_donor_info = partner_affiliation.custom_donor_info
      campaign = partner_affiliation.campaign
      PartnerAffiliation.create(
        donor: donor,
        partner: partner,
        campaign: campaign,
        custom_donor_info: custom_donor_info)
      nil
    end
  end
end
