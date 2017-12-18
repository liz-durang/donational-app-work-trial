# == Schema Information
#
# Table name: organizations
#
#  ein              :string           not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  local_impact     :boolean
#  global_impact    :boolean
#  immediate_impact :boolean
#  long_term_impact :boolean
#  description      :text
#  cause_area       :string
#  deactivated_at   :datetime
#

FactoryBot.define do
  factory :organization do
    sequence :ein do |n|
      "org_#{n}"
    end
    sequence :name do |n|
      "Organization #{n}"
    end
  end
end
