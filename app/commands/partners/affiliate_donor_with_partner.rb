module Partners
  class AffiliateDonorWithPartner < ApplicationCommand
    required do
      model :donor
      model :partner
    end

    optional do
      model :campaign
    end

    def execute
      return if already_associated_with_partner?
      return if donor_previously_contributed?

      PartnerAffiliation.create(donor: donor, partner: partner, campaign: campaign)

      nil
    end

    private

    def already_associated_with_partner?
      PartnerAffiliation.exists?(donor: donor)
    end

    def donor_previously_contributed?
      Contributions::HasPreviousOrUpcomingContribution.call(donor: donor)
    end
  end
end
