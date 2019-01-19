# == Schema Information
#
# Table name: grants
#
#  id               :uuid             not null, primary key
#  organization_ein :string
#  amount_cents     :integer
#  receipt          :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  scheduled_at     :datetime
#  processed_at     :datetime
#

FactoryBot.define do
  factory :grant do
    organization
    amount_cents { 123 }
    scheduled_at { 1.day.ago }
    processed_at { nil }
  end
end
