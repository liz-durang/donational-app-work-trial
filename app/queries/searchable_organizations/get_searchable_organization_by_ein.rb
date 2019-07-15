module SearchableOrganizations
  class GetSearchableOrganizationByEin < ApplicationQuery
    def initialize(relation = SearchableOrganization.all)
      @relation = relation
    end

    def call(ein:)
      return nil if ein.blank?

      @relation.find_by(ein: ein)
    end
  end
end
