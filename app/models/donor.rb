class Donor < ApplicationRecord
  has_many :subscriptions
  has_one :active_subscription, -> { where(deactivated_at: nil) }, class_name: 'Subscription'
end
