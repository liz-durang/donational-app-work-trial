# == Schema Information
#
# Table name: partner_affiliations
#
#  id                :uuid             not null, primary key
#  donor_id          :uuid
#  partner_id        :uuid
#  campaign_id       :uuid
#  custom_donor_info :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

FactoryBot.define do
  factory :partner_affiliation do
    partner
    donor
    campaign { create(:campaign, slug: SecureRandom.uuid) }
    custom_donor_info ""
  end
end
