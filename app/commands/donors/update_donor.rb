require Rails.root.join('lib','mutations','symbol_filter')
require Rails.root.join('lib','mutations','decimal_filter')

module Donors
  class UpdateDonor < ApplicationCommand
    required do
      model :donor
    end

    optional do
      string :first_name, strip: true
      string :last_name, strip: true
      string :email
      string :title, empty: true, strip: true
      string :house_name_or_number, empty: true, strip: true
      string :postcode, empty: true, strip: true
      boolean :uk_gift_aid_accepted
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
      return if donor.update(updateable_attributes)

      donor.errors.full_messages.each do |message|
        add_error(:donor, :validation_error, message)
      end
    end

    def updateable_attributes
      inputs.except(:donor)
    end
  end
end
