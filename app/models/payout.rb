class Payout < ApplicationRecord
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations
end
