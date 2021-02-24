# frozen_string_literal: true

module Partners
  class ListDonors < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(search:, partner:, page:, per_page: 10)
      return nil if partner.blank?

      if search.present?
        Donor.search search, where: { deactivated_at: nil, partner_id: partner.id }, page: page, per_page: per_page
      else
        Donor
          .where(deactivated_at: nil)
          .joins(:partner_affiliations)
          .where(partner_affiliations: { partner: partner })
          .distinct
          .order(updated_at: :desc)
          .page(page)
          .per(per_page)
      end
    end
  end
end
