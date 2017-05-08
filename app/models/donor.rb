# == Schema Information
#
# Table name: donors
#
#  id         :uuid             not null, primary key
#  first_name :string
#  last_name  :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Donor < ApplicationRecord
  has_many :subscriptions
  has_one :active_subscription, -> { where(deactivated_at: nil) }, class_name: 'Subscription'
  has_many :pay_ins, through: :subscriptions
  has_many :donations, through: :subscriptions
  has_many :active_allocations, through: :active_subscription
end
