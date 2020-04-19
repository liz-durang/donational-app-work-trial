# frozen_string_literal: true

# == Schema Information
#
# Table name: donations
#
#  id               :uuid             not null, primary key
#  portfolio_id     :uuid             not null
#  organization_ein :string           not null
#  allocation_id    :uuid
#  contribution_id  :uuid             not null
#  grant_id         :uuid
#  amount_cents     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# Tracks the part of a donor's contribution that was distributed to an organization.
class Donation < ApplicationRecord
  belongs_to :portfolio
  belongs_to :organization, foreign_key: 'organization_ein'
  belongs_to :allocation, optional: true
  belongs_to :contribution
  belongs_to :grant, optional: true
  delegate :donor, to: :contribution

  scope(:unpaid, -> { where(grant: nil) })
  scope(:paid, -> { where.not(grant: nil) })

  validates :contribution, :organization, :portfolio, presence: true

  monetize :amount_cents
end
