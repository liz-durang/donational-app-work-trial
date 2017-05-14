# == Schema Information
#
# Table name: donors
#
#  id         :uuid             not null, primary key
#  first_name :string
#  last_name  :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :donor do
  end
end
