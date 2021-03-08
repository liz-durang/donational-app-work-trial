module Partners
  class AffiliateDonorWithPartner < ApplicationCommand
    required do
      model :donor
      model :partner
    end

    optional do
      model :campaign
      string :referred_by_donor_id
    end

    def execute
      return if already_associated_with_partner?

      return if donor_previously_contributed?

      PartnerAffiliation.create(
        donor: donor,
        partner: partner,
        campaign: campaign,
        referred_by_donor: referred_by_donor
      )

      TriggerNewDonorWebhook.perform_async(donor.id, partner.id)

      nil
    end

    private

    def already_associated_with_partner?
      PartnerAffiliation.exists?(donor: donor)
    end

    def donor_previously_contributed?
      Contributions::HasPreviousOrUpcomingContribution.call(donor: donor)
    end

    def referred_by_donor
      Donors::GetDonorById.call(id: referred_by_donor_id)
    end
  end
end
