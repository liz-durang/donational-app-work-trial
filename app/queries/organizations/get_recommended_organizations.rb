module Organizations
  class GetRecommendedOrganizations < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call
      @relation.where(
        deactivated_at: nil,
        suggested_by_donor: nil
      ).order(cause_area: :asc, name: :asc)
    end
  end
end
