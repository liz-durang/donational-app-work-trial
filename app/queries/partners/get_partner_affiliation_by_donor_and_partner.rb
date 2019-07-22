module Partners
  class GetPartnerAffiliationByDonorAndPartner < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:, partner:)
      @relation.find_by(donor: donor, partner: partner)
    end
  end
end
