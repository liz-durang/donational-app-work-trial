# == Schema Information
#
# Table name: managed_portfolios
#
#  id           :uuid             not null, primary key
#  partner_id   :uuid
#  portfolio_id :uuid
#  name         :string
#  description  :text
#  hidden_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :managed_portfolio do
    partner
    portfolio
    name { "MyString" }
    description { "MyText" }
    hidden_at { "2018-06-29 17:31:58" }
  end
end
