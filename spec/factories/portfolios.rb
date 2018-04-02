# == Schema Information
#
# Table name: portfolios
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  contribution_frequency          :string
#  deactivated_at                  :datetime
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  contribution_amount_cents       :integer
#  contribution_platform_fee_cents :integer
#

FactoryBot.define do
  factory :portfolio do
    donor
  end
end
