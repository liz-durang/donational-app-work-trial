# == Schema Information
#
# Table name: organizations
#
#  ein        :string           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :organization do
    sequence :ein do |n|
      "org_#{n}"
    end
    sequence :name do |n|
      "Organization #{n}"
    end
  end
end
