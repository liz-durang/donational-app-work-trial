# == Schema Information
#
# Table name: allocations
#
#  id               :uuid             not null, primary key
#  subscription_id  :uuid
#  organization_ein :string
#  percentage       :integer
#  deactivated_at   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryGirl.define do
  factory :allocation do
    subscription
    organization
    percentage 0
  end
end
