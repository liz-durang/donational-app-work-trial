module Partners
  class GetDonorExport < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(partner:)
      return nil if partner.blank?

      @relation
        .left_joins(partner_affiliations: [:partner, :campaign])
        .where(partner_affiliations: { partner: partner })
        .left_joins(recurring_contributions: { portfolio: [:managed_portfolio]})
        .where('recurring_contributions.created_at = (SELECT MAX(recurring_contributions.created_at) FROM recurring_contributions WHERE recurring_contributions.donor_id = donors.id)')
        .select(
          'donors.id as donor_id',
          'recurring_contributions.id AS recurring_contribution_id',
          'donors.created_at as donor_joined_at',
          :first_name,
          :last_name,
          :email,
          'partners.name as partner',
          'campaigns.title as campaign',
          "COALESCE(managed_portfolios.name, 'Custom Portfolio') AS current_portfolio",
          :frequency,
          'CAST(CAST(amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS contribution_amount',
          'start_at AS donations_start_at',
          'recurring_contributions.created_at AS plan_updated_at',
          'recurring_contributions.deactivated_at AS plan_cancelled_at',
          'recurring_contributions.partner_contribution_percentage AS partner_contribution_percentage',
          *custom_donor_fields_for(partner)
        )
        .order('donors.created_at')
    end

    private

    def custom_donor_fields_for(partner)
      partner.donor_questions.map(&:name).map do |q|
        "custom_donor_info->>'#{q}' as #{q}"
      end
    end
  end
end
