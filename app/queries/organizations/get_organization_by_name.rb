module Organizations
  class GetOrganizationByName < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(name:)
      return nil if name.blank?

      @relation.find_by(name: name)
    end
  end
end
