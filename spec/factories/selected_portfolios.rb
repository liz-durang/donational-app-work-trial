# == Schema Information
#
# Table name: selected_portfolios
#
#  id             :bigint(8)        not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :selected_portfolio do
    donor
    portfolio
  end
end
