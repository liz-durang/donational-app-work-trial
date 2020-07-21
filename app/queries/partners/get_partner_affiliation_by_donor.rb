module Partners
  class GetPartnerAffiliationByDonor < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:)
      @relation.order(created_at: :desc).where(donor: donor).first
    end
  end
end
