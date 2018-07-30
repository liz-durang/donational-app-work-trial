module Partners
  class GetDonorExport < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(partner:)
      return nil if partner.blank?

      @relation
        .joins(partner_affiliations: [:partner, :campaign])
        .where(partner_affiliations: { partner: partner })
        .left_joins(recurring_contributions: { portfolio: [:managed_portfolio]})
        .where(recurring_contributions: { deactivated_at: nil })
        .select(
          'donors.id as donor_id',
          :first_name,
          :last_name,
          :email,
          'partners.name as partner',
          'campaigns.title as campaign',
          "COALESCE(managed_portfolios.name, 'Unmanaged Portfolio') AS current_portfolio",
          :frequency,
          'CAST(CAST(amount_cents / 100.0 AS DECIMAL(10,2)) AS VARCHAR) AS contribution_amount',
          'start_at AS donation_plan_start_date',
          'recurring_contributions.deactivated_at AS donation_plan_stop_date',
          *custom_donor_fields_for(partner)
        )
    end

    private

    def custom_donor_fields_for(partner)
      partner.donor_questions.map(&:name).map do |q|
        "custom_donor_info->>'#{q}' as #{q}"
      end
    end
  end
end
