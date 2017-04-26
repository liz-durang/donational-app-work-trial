class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :payouts, foreign_key: 'organization_ein'

  validates :ein, presence: true
  validates :name, presence: true
end
