module Partners
  class GetGiftAidExport < ApplicationQuery
    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call(partner:, donated_between:)
      return nil if partner.blank?

      @relation
        .where(created_at: donated_between)
        .left_joins(:organization)
        .left_joins(contribution: [:donor])
        .where(contributions: { partner: partner })
        .where(donors: { uk_gift_aid_accepted: true })
        .select(
          'donors.title as title',
          :first_name,
          "REPLACE(last_name, '-', ' ') as last_name",
          :house_name_or_number,
          'UPPER(postcode) as postcode',
          'NULL as aggregated_donations',
          'NULL as sponsored_event',
          "to_char(donations.created_at, 'DD/MM/YY') as date",
          'CAST(donations.amount_cents / 100.0 AS DECIMAL(10,2)) AS amount'
        )
    end
  end
end
