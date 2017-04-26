class Subscription < ApplicationRecord
  belongs_to :donor
  has_many :pay_ins

  scope :active, -> { where.not(deactivated_at: nil) }
  scope :archived, -> { where(deactivated_at: nil) }

  extend Enumerize
  enumerize :pay_in_frequency, in: %w(monthly quarterly annually), predicates: true
end
