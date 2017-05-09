FactoryGirl.define do
  factory :organization do
    sequence :ein do |n|
      "org_#{n}"
    end
    sequence :name do |n|
      "Organization #{n}"
    end
  end
end
