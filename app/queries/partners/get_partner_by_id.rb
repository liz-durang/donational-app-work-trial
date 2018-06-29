module Partners
  class GetPartnerById  < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
