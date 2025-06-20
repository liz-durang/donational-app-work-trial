module Partners
  class GetGiftAidExport < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(partner:, donated_between:)
      return nil if partner.blank?

      @relation
        .where(created_at: donated_between)
        .where(payment_status: :succeeded)
        .left_joins(:donor)
        .where(partner: partner)
        .where(donors: { uk_gift_aid_accepted: true })
        .select(
          'donors.title as title',
          :first_name,
          "REPLACE(last_name, '-', ' ') as last_name",
          :house_name_or_number,
          'UPPER(postcode) as postcode',
          'NULL as aggregated_donations',
          'NULL as sponsored_event',
          "to_char(contributions.created_at, 'DD/MM/YY') as date",
          'CAST(contributions.amount_cents / 100.0 AS DECIMAL(10,2)) AS amount'
        )
    end
  end
end
