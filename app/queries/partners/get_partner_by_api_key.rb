module Partners
  class GetPartnerByApiKey  < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call(api_key:)
      return nil if api_key.blank?

      @relation.find_by(api_key: api_key)
    end
  end
end
