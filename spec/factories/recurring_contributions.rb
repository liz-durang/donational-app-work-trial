# == Schema Information
#
# Table name: recurring_contributions
#
#  id             :uuid             not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  start_at       :datetime         not null
#  deactivated_at :datetime
#  frequency      :string
#  amount_cents   :integer
#  tips_cents     :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :recurring_contribution do
    donor
    portfolio
    frequency :monthly
    amount_cents 1
    tips_cents 1
    start_at Time.zone.now
  end
end
