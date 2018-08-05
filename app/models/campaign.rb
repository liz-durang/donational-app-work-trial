# == Schema Information
#
# Table name: campaigns
#
#  id                           :uuid             not null, primary key
#  partner_id                   :uuid
#  title                        :string
#  description                  :text
#  slug                         :string
#  target_amount_cents          :integer
#  default_contribution_amounts :string           is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#

class Campaign < ApplicationRecord
  belongs_to :partner
  has_one_attached :banner_image

  validates :slug, uniqueness: true
end
