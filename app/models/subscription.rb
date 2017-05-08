# == Schema Information
#
# Table name: subscriptions
#
#  id                  :uuid             not null, primary key
#  donor_id            :uuid
#  annual_income_cents :integer
#  donation_rate       :decimal(, )
#  pay_in_frequency    :string
#  deactivated_at      :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Subscription < ApplicationRecord
  belongs_to :donor
  has_many :pay_ins
  has_many :allocations
  has_many :active_allocations, -> { where(deactivated_at: nil) }, class_name: 'Allocation'
  has_many :donations

  scope :active, -> { where.not(deactivated_at: nil) }
  scope :archived, -> { where(deactivated_at: nil) }

  extend Enumerize
  enumerize :pay_in_frequency, in: %w(monthly quarterly annually), predicates: true
end
