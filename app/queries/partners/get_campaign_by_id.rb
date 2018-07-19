module Partners
  class GetCampaignById < ApplicationQuery
    def initialize(relation = Campaign.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
