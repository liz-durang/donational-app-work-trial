# frozen_string_literal: true

# == Schema Information
#
# Table name: donors
#
#  id                                          :uuid             not null, primary key
#  first_name                                  :string
#  last_name                                   :string
#  email                                       :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  donation_rate                               :decimal(, )
#  annual_income_cents                         :integer
#  donated_prior_year                          :boolean
#  satisfaction_with_prior_donation            :string
#  donation_rate_expected_from_individuals     :decimal(, )
#  surprised_by_average_american_donation_rate :string
#  include_immediate_impact_organizations      :boolean          default(TRUE)
#  include_long_term_impact_organizations      :boolean          default(TRUE)
#  include_local_organizations                 :boolean          default(TRUE)
#  include_global_organizations                :boolean          default(TRUE)
#  username                                    :string
#  giving_challenges                           :string           default([]), is an Array
#  reasons_why_i_choose_an_organization        :string           default([]), is an Array
#  contribution_frequency                      :string
#  portfolio_diversity                         :integer
#  entity_name                                 :string
#  title                                       :string
#  house_name_or_number                        :string
#  postcode                                    :string
#  uk_gift_aid_accepted                        :boolean          default(FALSE), not null
#

FactoryBot.define do
  factory :donor do
    trait :entity do
      entity_name { 'Company' }
      first_name { nil }
      last_name { nil }
    end

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    trait :with_uk_gift_aid_accepted do
      uk_gift_aid_accepted { true }
      title { Faker::Name.prefix }
      house_name_or_number { Faker::Address.street_address }
      postcode { 'PO1 3AX' }
    end
  end
end
