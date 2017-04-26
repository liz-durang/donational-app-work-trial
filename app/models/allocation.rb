class Allocation < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations

  scope :active, -> { where.not(deactivated_at: nil) }
  scope :archived, -> { where(deactivated_at: nil) }
end
