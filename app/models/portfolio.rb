# == Schema Information
#
# Table name: portfolios
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  contribution_frequency          :string
#  deactivated_at                  :datetime
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  contribution_amount_cents       :integer
#  contribution_platform_fee_cents :integer
#

# A donor's portfolio of charities
#
# Note:
#   Portfolios are never updated nor destroyed when the donation rate or amount changes.
#   Instead, we deactivate it and create a new portfolio which helps to keep a clear audit trail
class Portfolio < ApplicationRecord
  belongs_to :donor

  has_many :contributions
  has_many :allocations
  has_many :active_allocations,
           -> { where(deactivated_at: nil) },
           class_name: 'Allocation'
  has_many :donations

  scope :active, Portfolios::GetActivePortfolios

  extend Enumerize
  enumerize :contribution_frequency,
            in: %w[once monthly quarterly annually never],
            predicates: true

  def active?
    deactivated_at.blank?
  end
end
