# == Schema Information
#
# Table name: pay_outs
#
#  id               :uuid             not null, primary key
#  organization_ein :string
#  amount_cents     :integer
#  receipt          :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  scheduled_at     :datetime
#  processed_at     :datetime
#

class PayOut < ApplicationRecord
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations
end
