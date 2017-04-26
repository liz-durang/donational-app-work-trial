class Donor < ApplicationRecord
  has_many :subscriptions
  has_one :active_subscription, -> { where(deactivated_at: nil) }, class_name: 'Subscription'
  has_many :pay_ins, through: :subscriptions
  has_many :donations, through: :subscriptions
  has_many :active_allocations, through: :active_subscription
end
