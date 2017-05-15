# == Schema Information
#
# Table name: donations
#
#  id               :uuid             not null, primary key
#  subscription_id  :uuid             not null
#  organization_ein :string           not null
#  allocation_id    :uuid             not null
#  pay_in_id        :uuid             not null
#  pay_out_id        :uuid
#  amount_cents     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Donation < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  belongs_to :organization, foreign_key: 'organization_ein'
  belongs_to :allocation
  belongs_to :pay_in
  belongs_to :pay_out, optional: true

  scope(:unpaid, -> { where(pay_out: nil) })
  scope(:paid, -> { where.not(pay_out: nil) })

  validates :pay_in, :allocation, :organization, :subscription, presence: true
end
