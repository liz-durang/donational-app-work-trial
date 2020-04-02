require Rails.root.join('lib','mutations','symbol_filter')
require Rails.root.join('lib','mutations','decimal_filter')

module Donors
  class UpdateUkDonor < ApplicationCommand
    required do
      model :uk_donor
      string :first_name
      string :last_name
      string :email
      string :title
      string :house_name_or_number
      string :postcode
    end

    optional do
      decimal :donation_rate
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
      symbol :portfolio_diversity
    end

    def execute
      add_error(:uk_donor, :wrong_values, 'Wrong values') unless UkDonor.new(updateable_attributes).valid?
      uk_donor.update(updateable_attributes)
    end

    def updateable_attributes
      inputs.except(:uk_donor)
    end
  end
end
