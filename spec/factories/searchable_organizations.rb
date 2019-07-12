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
    sequence :tsv do |n|
      "'#{n}':2 'chariti':1"
    end
  end
end
