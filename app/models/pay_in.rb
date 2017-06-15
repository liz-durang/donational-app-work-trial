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
#  scheduled_at    :datetime
#  processed_at    :datetime
#

# Funds withdrawn from a Donor and transferred to Donational
class PayIn < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  has_many :donations
end
