# == Schema Information
#
# Table name: contributions
#
#  id              :uuid             not null, primary key
#  portfolio_id :uuid
#  amount_cents    :integer
#  receipt         :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  scheduled_at    :datetime
#  processed_at    :datetime
#

# Funds withdrawn from a Donor and transferred to Donational
class Contribution < ApplicationRecord
  belongs_to :portfolio
  has_one :donor, through: :portfolio
  has_many :donations
end
