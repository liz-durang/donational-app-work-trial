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
#  username                                    :string
#

class Donor < ApplicationRecord
  has_many :portfolios
  has_one :active_portfolio, -> { where(deactivated_at: nil) }, class_name: 'Portfolio'
  has_many :contributions, through: :portfolios
  has_many :donations, through: :portfolios
  has_many :active_allocations, through: :active_portfolio

  before_create :generate_username

  def generate_username(conflict_resolving_suffix: nil)
    return if username.present?

    candidate_username = [name, conflict_resolving_suffix].join('-').parameterize

    if Donor.exists?(username: candidate_username)
      generate_username(conflict_resolving_suffix: SecureRandom.uuid[0..3])
    else
      self.username = candidate_username
    end
  end

  def name
    [first_name, last_name].compact.join(' ')
  end

  def account_holder?
    email.present?
  end
end
