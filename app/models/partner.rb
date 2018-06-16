# == Schema Information
#
# Table name: partners
#
#  id                      :uuid             not null, primary key
#  name                    :string
#  website_url             :string
#  description             :text
#  platform_fee_percentage :decimal(, )      default(0.0)
#  primary_branding_color  :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class Partner < ApplicationRecord
end
