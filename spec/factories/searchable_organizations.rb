# == Schema Information
#
# Table name: searchable_organizations
#
#  ein              :string           not null, primary key
#  name             :string           not null
#  ico              :string
#  street           :string
#  city             :string
#  state            :string
#  zip              :string
#  org_group        :string
#  subsection       :string
#  affiliation      :string
#  classification   :string
#  ruling           :string
#  deductibility    :string
#  foundation       :string
#  activity         :string
#  organization     :string
#  status           :string
#  tax_period       :string
#  asset_cd         :string
#  income_cd        :string
#  filing_req_cd    :string
#  pf_filing_req_cd :string
#  acct_pd          :string
#  asset_amt        :string
#  income_amt       :string
#  revenue_amt      :string
#  ntee_cd          :string
#  sort_name        :string
#

FactoryBot.define do
  factory :searchable_organization do
    sequence :ein do |n|
      "org_#{n}_#{SecureRandom.uuid[0..6]}"
    end
    sequence :name do |n|
      "Charity #{n}"
    end
    sequence :state do |n|
      "State #{n}"
    end

    trait :reindex do
      after(:create) do |searchable_organization, _evaluator|
        searchable_organization.reindex(refresh: true)
      end
    end
  end
end
