module Partners
  class GetDonorExport < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(partner:)
      return nil if partner.blank?

      @relation
        .where(deactivated_at: nil)
        .left_joins(partner_affiliations: [:partner, :campaign])
        .where(partner_affiliations: { partner: partner })
        .joins('LEFT OUTER JOIN payment_methods ON (payment_methods.donor_id = donors.id AND payment_methods.deactivated_at IS NULL)')
        .left_joins(subscriptions: { portfolio: [:managed_portfolio]})
        .where('subscriptions.created_at = (SELECT MAX(subscriptions.created_at) FROM subscriptions WHERE subscriptions.donor_id = donors.id)')
        .select(
          'donors.id as donor_id',
          'subscriptions.id AS subscription_id',
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
          'subscriptions.created_at AS plan_updated_at',
          'subscriptions.deactivated_at AS plan_cancelled_at',
          'subscriptions.trial_start_at AS trial_started_at',
          'subscriptions.trial_deactivated_at AS trial_cancelled_at',
          'subscriptions.partner_contribution_percentage AS partner_contribution_percentage',
          "replace(payment_methods.type, 'PaymentMethods::','') AS payment_method",
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
