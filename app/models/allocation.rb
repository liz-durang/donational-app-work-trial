# == Schema Information
#
# Table name: allocations
#
#  id               :uuid             not null, primary key
#  subscription_id  :uuid
#  organization_ein :string
#  percentage       :integer
#  deactivated_at   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Allocation < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations

  scope :active, Allocations::GetActiveAllocations

  def active?
    deactivated_at.blank?
  end
end
