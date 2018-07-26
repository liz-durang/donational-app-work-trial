# == Schema Information
#
# Table name: partners
#
#  id                           :uuid             not null, primary key
#  name                         :string
#  website_url                  :string
#  description                  :text
#  platform_fee_percentage      :decimal(, )      default(0.0)
#  primary_branding_color       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donor_questions_schema       :jsonb
#  payment_processor_account_id :string
#

require 'rails_helper'

RSpec.describe Partner, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
