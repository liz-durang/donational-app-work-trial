# == Schema Information
#
# Table name: contributions
#
#  id                           :uuid             not null, primary key
#  portfolio_id                 :uuid
#  amount_cents                 :integer
#  receipt                      :json
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  scheduled_at                 :datetime
#  processed_at                 :datetime
#  tips_cents                   :integer          default(0)
#  donor_id                     :uuid
#  failed_at                    :datetime
#  payment_processor_fees_cents :integer
#  refunded_at                  :datetime
#  external_reference_id        :string
#

# Funds withdrawn from a Donor and transferred to Donational
class Contribution < ApplicationRecord
  belongs_to :portfolio
  belongs_to :donor
  has_many :donations
  has_many :organizations, through: :donations

  def amount_dollars
    amount_cents / 100.0
  end

  def total_charges_cents
    amount_cents + tips_cents
  end
end
