class AddPreferencesToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :donation_rate, :decimal
    add_column :donors, :annual_income_cents, :integer
    add_column :donors, :donated_prior_year, :boolean
    add_column :donors, :satisfaction_with_prior_donation, :string
    add_column :donors, :donation_rate_expected_from_individuals, :decimal
    add_column :donors, :surprised_by_average_american_donation_rate, :string
    add_column :donors, :include_immediate_impact_organizations, :boolean
    add_column :donors, :include_long_term_impact_organizations, :boolean
    add_column :donors, :include_local_organizations, :boolean
    add_column :donors, :include_global_organizations, :boolean
  end
end
