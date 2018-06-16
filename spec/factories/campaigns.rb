# == Schema Information
#
# Table name: campaigns
#
#  id                           :uuid             not null, primary key
#  partner_id                   :uuid
#  title                        :string
#  description                  :text
#  slug                         :string
#  target_amount_cents          :integer
#  default_contribution_amounts :string           is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#

FactoryBot.define do
  factory :campaign do
    partner
    title "MyString"
    slug "MyString"
    description "MyText"
    target_amount_cents 1
    default_contribution_amounts ""
  end
end
