# frozen_string_literal: true

# == Schema Information
#
# Table name: donations
#
#  id               :uuid             not null, primary key
#  portfolio_id     :uuid             not null
#  organization_ein :string           not null
#  allocation_id    :uuid
#  contribution_id  :uuid             not null
#  grant_id         :uuid
#  amount_cents     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :donation do
    portfolio
    organization
    allocation
    contribution
    grant { nil }
    amount_cents { 1 }
  end
end
