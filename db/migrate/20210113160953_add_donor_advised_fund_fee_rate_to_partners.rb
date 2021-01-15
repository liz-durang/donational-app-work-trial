class AddDonorAdvisedFundFeeRateToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :donor_advised_fund_fee_percentage, :decimal, default: 0.01
  end
end
