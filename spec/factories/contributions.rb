# == Schema Information
#
# Table name: contributions
#
#  id              :uuid             not null, primary key
#  portfolio_id :uuid
#  amount_cents    :integer
#  receipt         :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  scheduled_at    :datetime
#  processed_at    :datetime
#

FactoryGirl.define do
  factory :contribution do
    portfolio
    amount_cents 123
    scheduled_at 1.day.ago
    processed_at nil
  end
end
