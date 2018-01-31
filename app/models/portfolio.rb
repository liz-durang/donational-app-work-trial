# == Schema Information
#
# Table name: portfolios
#
#  id                        :uuid             not null, primary key
#  donor_id                  :uuid
#  contribution_frequency    :string
#  deactivated_at            :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  contribution_amount_cents :integer
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

  def contribution_amount_dollars
    return target_contribition_amount_dollars.to_i if contribution_amount_cents.nil?

    (contribution_amount_cents / 100).to_i
  end

  def active?
    deactivated_at.blank?
  end

  def target_contribition_amount_dollars
    case contribution_frequency
    when 'annually'
      target_annual_contribution_amount_dollars
    when 'quarterly'
      target_quarterly_contribution_amount_dollars
    when 'monthly'
      target_monthly_contribution_amount_dollars
    when 'once'
      target_monthly_contribution_amount_dollars
    else
      nil
    end
  end

  def target_monthly_contribution_amount_dollars
    return nil unless target_annual_contribution_amount_dollars

    target_annual_contribution_amount_dollars / 12.0
  end

  def target_quarterly_contribution_amount_dollars
    return nil unless target_annual_contribution_amount_dollars

    target_annual_contribution_amount_dollars / 4.0
  end

  private

  def target_annual_contribution_amount_dollars
    return nil unless donor.annual_income_cents
    return nil unless donor.donation_rate

    donor.donation_rate * donor.annual_income_cents / 100
  end
end
