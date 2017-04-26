class Allocation < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  belongs_to :organization, foreign_key: 'organization_ein'

  scope :active, -> { where.not(deactivated_at: nil) }
  scope :archived, -> { where(deactivated_at: nil) }
end
