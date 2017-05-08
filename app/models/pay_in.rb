# == Schema Information
#
# Table name: pay_ins
#
#  id              :uuid             not null, primary key
#  subscription_id :uuid
#  amount_cents    :integer
#  receipt         :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class PayIn < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  has_many :donations
end
