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
        .left_joins(portfolio: [:managed_portfolio])
        .left_joins(contribution: [:donor])
        .where(contributions: { partner: partner })
        .select(
          'donors.id as donor_id',
          :first_name,
          :last_name,
          :email,
          'contributions.id as contribution_id',
          'CAST(CAST(contributions.amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS contribution_amount',
          'contributions.amount_currency as currency',
          'CAST(CAST(contributions.payment_processor_fees_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS payment_processor_fees',
          'CAST(CAST(contributions.platform_fees_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS platform_fees',
          'CAST(CAST(contributions.donor_advised_fund_fees_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS donor_advised_fund_fees',
          'donations.id as donation_id',
          'CAST(CAST(donations.amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS donation_amount',
          :organization_ein,
          'organizations.name as organization_name',
          "COALESCE(managed_portfolios.name, 'Custom Portfolio') AS portfolio_name",
          :created_at
        )
    end
  end
end
