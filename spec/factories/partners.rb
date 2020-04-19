# == Schema Information
#
# Table name: partners
#
#  id                               :uuid             not null, primary key
#  name                             :string
#  website_url                      :string
#  description                      :text
#  platform_fee_percentage          :decimal(, )      default(0.0)
#  primary_branding_color           :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  donor_questions_schema           :jsonb
#  payment_processor_account_id     :string
#  api_key                          :string
#  operating_costs_text             :string
#  operating_costs_organization_ein :string
#  currency                         :string           default("usd"), not null
#

FactoryBot.define do
  factory :partner do
    name { "MyString" }
    website_url { "MyString" }
    description { "MyString" }
    platform_fee_percentage { "2" }
    primary_branding_color { "MyString" }
    donor_questions_schema { { questions: [] } }
    payment_processor_account_id { 'acc_123' }

    trait :default do
      name { Partner::DEFAULT_PARTNER_NAME }
      website_url { 'https://donational.org' }
    end
  end
end
