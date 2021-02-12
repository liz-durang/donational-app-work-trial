# == Schema Information
#
# Table name: campaigns
#
#  id                            :uuid             not null, primary key
#  partner_id                    :uuid
#  title                         :string
#  description                   :text
#  slug                          :string
#  target_amount_cents           :integer
#  default_contribution_amounts  :string           is an Array
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  contribution_amount_help_text :string
#  allow_one_time_contributions  :boolean          default(TRUE), not null
#  minimum_contribution_amount   :integer          default(10)
#

FactoryBot.define do
  factory :campaign do
    partner
    title { "MyString" }
    slug { SecureRandom.uuid }
    description { "MyText" }
    target_amount_cents { 1 }
    default_contribution_amounts { "" }
  end
end
