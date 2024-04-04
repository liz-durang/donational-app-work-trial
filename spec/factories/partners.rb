# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id                                :uuid             not null, primary key
#  name                              :string
#  website_url                       :string
#  description                       :text
#  platform_fee_percentage           :decimal(, )      default(0.0)
#  primary_branding_color            :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  donor_questions_schema            :jsonb
#  payment_processor_account_id      :string
#  api_key                           :string
#  operating_costs_text              :string
#  operating_costs_organization_ein  :string
#  currency                          :string           default("usd"), not null
#  email_receipt_preamble            :text
#  after_donation_thank_you_page_url :string
#  receipt_first_paragraph           :text
#  receipt_second_paragraph          :text
#  receipt_tax_info                  :text
#  receipt_charity_name              :string
#  donor_advised_fund_fee_percentage :decimal(, )      default(0.01)
#  uses_one_for_the_world_checkout   :boolean          default(FALSE), not null

FactoryBot.define do
  factory :partner do
    name { Faker::Company.name }
    website_url { Faker::Internet.url(path: nil) }
    description { Faker::Company.catch_phrase }
    platform_fee_percentage { '2' }
    primary_branding_color { 'MyString' }
    donor_questions_schema { { questions: [] } }
    payment_processor_account_id { "acc_#{Faker::Number.number(digits: 10)}" }

    trait :default do
      name { Partner::DEFAULT_PARTNER_NAME }
      website_url { 'https://donational.org' }
    end
  end
end
