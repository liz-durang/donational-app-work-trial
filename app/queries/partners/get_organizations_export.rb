module Partners
  class GetOrganizationsExport < ApplicationQuery
    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call(partner:, donated_between:)
      return nil if partner.blank?

      @relation
        .where(created_at: donated_between)
        .left_joins(:organization)
        .left_joins(:contribution)
        .where(contributions: { partner: partner })
        .group(:organization_ein)
        .select(
          :organization_ein,
          "CAST(SUM(donations.amount_cents) / 100.0 AS DECIMAL(10,2)) AS total_donations_amount_#{partner.currency}",
          'COUNT(donations.contribution_id) AS total_contributions',
          'COUNT(DISTINCT contributions.donor_id) AS unique_donors',
          '(array_agg(organizations.name))[1] AS organization_name'
        )
    end
  end
end
