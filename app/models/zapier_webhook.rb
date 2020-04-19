# == Schema Information
#
# Table name: zapier_webhooks
#
#  id         :uuid             not null, primary key
#  hook_url   :string
#  hook_type  :string
#  partner_id :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ZapierWebhook < ApplicationRecord
  belongs_to :partner
end
