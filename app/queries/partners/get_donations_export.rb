module Partners
  class GetDonationsExport < ApplicationQuery
    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call(partner:, donated_between:)
      return nil if partner.blank?

      @relation
        .where(created_at: donated_between)
        .left_joins(:organization)
        .left_joins(contribution: { donor: { partner_affiliations: [:partner, :campaign] } })
        .where(contributions: { donor: PartnerAffiliation.where(partner: partner).pluck(:donor_id) })
        .select(
          'donors.id as donor_id',
          :first_name,
          :last_name,
          :email,
          'contributions.id as contribution_id',
          'CAST(CAST(contributions.amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS contribution_amount',
          'donations.id as donation_id',
          'CAST(CAST(donations.amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS donation_amount',
          :organization_ein,
          'organizations.name as organization_name',
          :created_at
        )
    end
  end
end
