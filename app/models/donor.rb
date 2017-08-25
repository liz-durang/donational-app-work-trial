# == Schema Information
#
# Table name: donors
#
#  id                                          :uuid             not null, primary key
#  first_name                                  :string
#  last_name                                   :string
#  email                                       :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  donation_rate                               :decimal(, )
#  annual_income_cents                         :integer
#  donated_prior_year                          :boolean
#  satisfaction_with_prior_donation            :string
#  donation_rate_expected_from_individuals     :decimal(, )
#  surprised_by_average_american_donation_rate :string
#  include_immediate_impact_organizations      :boolean          default(TRUE)
#  include_long_term_impact_organizations      :boolean          default(TRUE)
#  include_local_organizations                 :boolean          default(TRUE)
#  include_global_organizations                :boolean          default(TRUE)
#

class Donor < ApplicationRecord
  has_many :subscriptions
  has_one :active_subscription, -> { where(deactivated_at: nil) }, class_name: 'Subscription'
  has_many :pay_ins, through: :subscriptions
  has_many :donations, through: :subscriptions
  has_many :active_allocations, through: :active_subscription

  def name
    [first_name, last_name].compact.join(' ')
  end

  def account_holder?
    email.present?
  end
end
