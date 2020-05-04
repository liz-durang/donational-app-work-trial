# == Schema Information
#
# Table name: managed_portfolios
#
#  id            :uuid             not null, primary key
#  partner_id    :uuid
#  portfolio_id  :uuid
#  name          :string
#  description   :text
#  featured      :boolean
#  hidden_at     :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  display_order :integer
#

class ManagedPortfolio < ApplicationRecord
  belongs_to :partner
  belongs_to :portfolio
  has_one_attached :image

  delegate :size, to: :portfolio

  def available_to_new_donors?
    hidden_at.blank?
  end
end
