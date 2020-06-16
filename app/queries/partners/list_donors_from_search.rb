module Partners
  class ListDonorsFromSearch < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(search:, partner:, page:)
      return nil if search.blank? || partner.blank?
      Donor.search search, where: { partner_id: partner.id }, page: page, per_page: 10
    end
  end
end
