# == Schema Information
#
# Table name: portfolios
#
#  id             :uuid             not null, primary key
#  donor_id       :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :portfolio do
    donor
  end
end
