# == Schema Information
#
# Table name: contributions
#
#  id           :uuid             not null, primary key
#  portfolio_id :uuid
#  amount_cents :integer
#  receipt      :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  scheduled_at :datetime
#  processed_at :datetime
#  tips_cents   :integer          default(0)
#  donor_id     :uuid
#  failed_at    :datetime
#

FactoryBot.define do
  factory :contribution do
    donor
    portfolio
    amount_cents { 123 }
    tips_cents { 2 }
    scheduled_at { 1.day.ago }
    processed_at { nil }
    
    factory :contribution_with_donations_to_organizations do
      transient do
        organizations { [] }
      end

      after(:create) do |contribution, evaluator|
        evaluator.organizations.each do |organization|
          create(:donation, organization: organization, contribution: contribution)
        end
      end
    end
  end
end
