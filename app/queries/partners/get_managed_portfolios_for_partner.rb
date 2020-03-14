module Partners
  class GetManagedPortfoliosForPartner < ApplicationQuery
    def initialize(relation = ManagedPortfolio.all)
      @relation = relation
    end

    def call(partner:)
      return nil if partner.blank?

      @relation
        .where(partner: partner)
        .where(hidden_at: nil)
        .order(display_order: :asc)
    end
  end
end
