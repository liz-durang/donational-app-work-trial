module Partners
  class GetPartnerAffiliationByDonor < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:)
      @relation.find_by(donor: donor)
    end
  end
end
