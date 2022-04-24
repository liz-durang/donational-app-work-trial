# frozen_string_literal: true

# == Schema Information
#
# Table name: subscriptions
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

class Subscription < ApplicationRecord
  belongs_to :donor
  belongs_to :portfolio
  belongs_to :partner
  validates :amount_currency, presence: true

  extend Enumerize
  enumerize :frequency, in: %w[monthly quarterly annually once], predicates: true

  delegate :name, to: :donor, prefix: true
  delegate :email, to: :donor, prefix: true

  def active?
    return false if !future_contribution_scheduled?
    
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

    return start_at if start_at.to_date > today && !monthly?

    if once?
      return nil if last_scheduled_at && last_scheduled_at > start_at

      start_at
    elsif monthly?
      if start_at.to_date < today
        next_15th_of_the_month_after(today)
      else
        next_15th_of_the_month_after(start_at)
      end
    elsif quarterly?
      today.next_quarter.at_beginning_of_quarter
    elsif annually?
      next_annually_contribution
    end
  end

  def trial_active?
    return false if start_at.blank? || start_at.to_date < Date.today

    trial_deactivated_at.blank? && trial_amount_cents.present? && trial_amount_cents > 0
  end

  def trial_amount_dollars
    trial_amount_cents / 100.0
  end

  def trial_future_contribution_scheduled?
    return false if trial_next_contribution_at.nil?

    trial_next_contribution_at >= Date.today
  end

  def trial_next_contribution_at
    return nil unless trial_active?

    if trial_start_at.to_date < Date.today
      next_15th_of_the_month_after(Date.today)
    else
      next_15th_of_the_month_after(trial_start_at)
    end
  end

  private

  def next_15th_of_the_month_after(date)
    if date.day < 15
      month = date.month
      year = date.year
    else
      month = date.next_month.month
      year = date.next_month.year
    end

    Date.new(year, month, 15)
  end

  def next_annually_contribution
    if Date.new(Date.today.year, start_at.month, start_at.day) > Date.today
      Date.new(Date.today.year, start_at.month, start_at.day)
    else
      Date.new(Date.today.year + 1, start_at.month, start_at.day)
    end
  end
end
