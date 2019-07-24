module Partners
  class GetDefaultPartnerByName  < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call
      @relation.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
