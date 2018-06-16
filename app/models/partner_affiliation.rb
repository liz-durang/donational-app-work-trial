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

class PartnerAffiliation < ApplicationRecord
  belongs_to :partner
  belongs_to :donor
  belongs_to :campaign
end
