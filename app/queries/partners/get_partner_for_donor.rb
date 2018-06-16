module Partners
  class GetPartnerForDonor < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:)
      affiliation = @relation.find_by(donor: donor)
      affiliation.partner unless affiliation.nil?
    end
  end
end
