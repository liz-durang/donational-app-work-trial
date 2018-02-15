module Organization
  class GetOrganizationByEin  < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(ein:)
      return nil if ein.blank?

      @relation.find_by(ein: ein)
    end
  end
end
