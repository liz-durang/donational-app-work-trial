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
