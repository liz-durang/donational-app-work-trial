module Donors
  class UpdateDonor < ApplicationCommand
    required do
      model :donor
    end

    optional do
      string :first_name
      string :last_name
      string :email
      float :donation_rate
      integer :annual_income_cents
      boolean :donated_prior_year
      boolean :include_local_organizations
      boolean :include_global_organizations
      boolean :include_long_term_impact_organizations
      string :satisfaction_with_prior_donation
      string :surprised_by_average_american_donation_rate
      string :payment_processor_customer_id
      array :giving_challenges
      array :reasons_why_i_choose_an_organization
      string :contribution_frequency
      integer :portfolio_diversity
    end

    def execute
      donor.update!(updateable_attributes)
    end

    def updateable_attributes
      inputs.except(:donor)
    end
  end
end
