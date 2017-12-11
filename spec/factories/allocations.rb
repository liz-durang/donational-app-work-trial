# == Schema Information
#
# Table name: allocations
#
#  id               :uuid             not null, primary key
#  portfolio_id  :uuid
#  organization_ein :string
#  percentage       :integer
#  deactivated_at   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :allocation do
    portfolio
    organization
    percentage 0
  end
end
