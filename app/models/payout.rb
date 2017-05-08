# == Schema Information
#
# Table name: payouts
#
#  id               :uuid             not null, primary key
#  organization_ein :string
#  amount_cents     :integer
#  receipt          :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Payout < ApplicationRecord
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations
end
