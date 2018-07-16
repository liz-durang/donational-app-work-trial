# == Schema Information
#
# Table name: allocations
#
#  id               :uuid             not null, primary key
#  portfolio_id     :uuid
#  organization_ein :string
#  percentage       :integer
#  deactivated_at   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# The percentage of a donor's contribution that is to be distributed to an organization per cycle
class Allocation < ApplicationRecord
  belongs_to :portfolio
  has_one :donor, through: :portfolio
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations

  scope :active, Portfolios::GetActiveAllocations

  delegate :name, to: :organization, prefix: true

  def active?
    deactivated_at.blank?
  end
end
