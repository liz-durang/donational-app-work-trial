# == Schema Information
#
# Table name: managed_portfolios
#
#  id           :uuid             not null, primary key
#  partner_id   :uuid
#  portfolio_id :uuid
#  name         :string
#  description  :text
#  hidden_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ManagedPortfolio < ApplicationRecord
  belongs_to :partner
  belongs_to :portfolio

  delegate :size, to: :portfolio
  def available_to_new_donors?
    hidden_at.blank?
  end
end
