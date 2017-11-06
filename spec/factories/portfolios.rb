# == Schema Information
#
# Table name: portfolios
#
#  id                  :uuid             not null, primary key
#  donor_id            :uuid
#  annual_income_cents :integer
#  donation_rate       :decimal(, )
#  contribution_frequency    :string
#  deactivated_at      :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryGirl.define do
  factory :portfolio do
    donor
  end
end
