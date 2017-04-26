class Donation < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  belongs_to :organization, foreign_key: 'organization_ein'
  belongs_to :allocation
  belongs_to :pay_in
  belongs_to :payout

  scope :unpaid, -> { where(payout: nil) }
  scope :paid, -> { where.not(payout: nil) }

  validates :pay_in, :allocation, :organization, :subscription, presence: true
end
