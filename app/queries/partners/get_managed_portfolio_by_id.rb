module Partners
  class GetManagedPortfolioById < ApplicationQuery
    def initialize(relation = ManagedPortfolio.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
