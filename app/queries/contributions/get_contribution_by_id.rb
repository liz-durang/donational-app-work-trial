module Contributions
  class GetContributionById  < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
