# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  ein                       :string           not null, primary key
#  name                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  local_impact              :boolean
#  global_impact             :boolean
#  immediate_impact          :boolean
#  long_term_impact          :boolean
#  cause_area                :string
#  deactivated_at            :datetime
#  mission                   :text
#  context                   :text
#  impact                    :text
#  why_you_should_care       :text
#  website_url               :string
#  annual_report_url         :string
#  financials_url            :string
#  form_990_url              :string
#  recommended_by            :string           default([]), is an Array
#  suggested_by_donor_id     :uuid
#  program_restriction       :string
#  routing_organization_name :string
#

FactoryBot.define do
  factory :organization do
    ein { Faker::Company.ein }
    name { Faker::Company.name }
  end
end
