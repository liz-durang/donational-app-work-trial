# == Schema Information
#
# Table name: selected_portfolios
#
#  id             :bigint(8)        not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class SelectedPortfolio < ApplicationRecord
  belongs_to :donor
  belongs_to :portfolio

  def active?
    deactivated_at.nil?
  end
end
