module Partners
  class GetCampaignBySlug < ApplicationQuery
    def initialize(relation = Campaign.all)
      @relation = relation
    end

    def call(slug:)
      return nil if slug.blank?

      @relation.find_by(slug: slug)
    end
  end
end
