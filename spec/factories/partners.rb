# == Schema Information
#
# Table name: partners
#
#  id                           :uuid             not null, primary key
#  name                         :string
#  website_url                  :string
#  description                  :text
#  platform_fee_percentage      :decimal(, )      default(0.0)
#  primary_branding_color       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donor_questions_schema       :jsonb
#  payment_processor_account_id :string
#

FactoryBot.define do
  factory :partner do
    name "MyString"
    website_url "MyString"
    platform_fee_percentage "9.99"
    primary_branding_color "MyString"
  end
end
