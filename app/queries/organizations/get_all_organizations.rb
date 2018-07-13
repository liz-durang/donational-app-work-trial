module Organizations
  class GetAllOrganizations < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call
      @relation.order(name: :asc)
    end
  end
end
