# == Schema Information
#
# Table name: donations
#
#  id               :uuid             not null, primary key
#  subscription_id  :uuid             not null
#  organization_ein :string           not null
#  allocation_id    :uuid             not null
#  contribution_id        :uuid             not null
#  grant_id       :uuid
#  amount_cents     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryGirl.define do
  factory :donation do
    subscription
    organization
    allocation
    contribution
    grant nil
    amount_cents 1
  end
end
