module Partners
  class GetPartnerForDonor < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:)
      @relation.find_by(donor: donor).try(:partner) || default_partner
    end

    def default_partner
      Partner.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
