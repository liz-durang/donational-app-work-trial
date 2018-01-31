class RemoveDonationRateAndAnnualIncomeCentsFromPortfolio < ActiveRecord::Migration[5.1]
  def change
    remove_column :portfolios, :donation_rate, :decimal
    remove_column :portfolios, :annual_income_cents, :integer
  end
end
