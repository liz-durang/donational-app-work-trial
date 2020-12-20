# frozen_string_literal: true

# == Schema Information
#
# Table name: subscriptions
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  portfolio_id                    :uuid
#  start_at                        :datetime         not null
#  deactivated_at                  :datetime
#  frequency                       :string
#  amount_cents                    :integer
#  tips_cents                      :integer          default(0)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  last_reminded_at                :datetime
#  last_scheduled_at               :datetime
#  partner_id                      :uuid
#  partner_contribution_percentage :integer          default(0)
#  amount_currency                 :string           default("usd"), not null
#

FactoryBot.define do
  factory :subscription do
    donor
    portfolio
    partner
    frequency { :monthly }
    amount_cents { 1 }
    tips_cents { 1 }
    start_at { Time.zone.now }
    amount_currency { 'usd' }
  end
end
