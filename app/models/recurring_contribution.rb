# frozen_string_literal: true

# == Schema Information
#
# Table name: recurring_contributions
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  portfolio_id                    :uuid
#  start_at                        :datetime         not null
#  deactivated_at                  :datetime
#  frequency                       :string
#  amount_cents                    :integer
#  tips_cents                      :integer          default(0)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  last_reminded_at                :datetime
#  last_scheduled_at               :datetime
#  partner_id                      :uuid
#  partner_contribution_percentage :integer          default(0)
#  amount_currency                 :string           default("usd"), not null
#

class RecurringContribution < ApplicationRecord
  belongs_to :donor
  belongs_to :portfolio
  belongs_to :partner
  validates :amount_currency, presence: true

  extend Enumerize
  enumerize :frequency, in: %w[monthly quarterly annually once], predicates: true

  delegate :name, to: :donor, prefix: true
  delegate :email, to: :donor, prefix: true

  def active?
    deactivated_at.blank?
  end

  def started?
    return true if start_at.nil?

    start_at.to_date <= Date.today
  end

  def future_contribution_scheduled?
    return false if next_contribution_at.nil?

    next_contribution_at >= Date.today
  end

  def amount_dollars
    amount_cents / 100.0
  end

  def next_contribution_at
    today = Date.today

    return start_at if start_at.to_date > today

    if monthly?
      # Since we make a contribution immediately, the earlist start date for the
      # first automated contribution is the beginning of the following month`
      earliest_monthly = [today, start_at.at_beginning_of_month + 1.month].max

      next_15th_of_the_month_after(earliest_monthly)
    elsif quarterly?
      today.next_quarter.at_beginning_of_quarter
    elsif annually?
      Date.new(today.year + 1, start_at.month, start_at.day)
    end
  end

  private

  def next_15th_of_the_month_after(date)
    month = date.day < 15 ? date.month : date.next_month.month
    Date.new(date.year, month, 15)
  end
end
