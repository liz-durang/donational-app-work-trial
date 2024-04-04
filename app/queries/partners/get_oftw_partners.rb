module Partners
  class GetOftwPartners < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call
      @relation
        .where(deactivated_at: nil)
        .where(uses_one_for_the_world_checkout: true)
        .order(:name)
    end
  end
end
