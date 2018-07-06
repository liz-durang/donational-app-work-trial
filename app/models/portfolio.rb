# == Schema Information
#
# Table name: portfolios
#
#  id             :uuid             not null, primary key
#  donor_id       :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

# A donor's portfolio of charities
#
# Note:
#   Portfolios are never updated nor destroyed when the donation rate or amount changes.
#   Instead, we deactivate it and create a new portfolio which helps to keep a clear audit trail
class Portfolio < ApplicationRecord
  belongs_to :creator, class_name: 'Donor', optional: true

  has_many :contributions
  has_many :allocations
  has_many :active_allocations,
           -> { where(deactivated_at: nil) },
           class_name: 'Allocation'
  has_many :donations

  def active?
    deactivated_at.blank?
  end

  def size
    active_allocations.count
  end
end
