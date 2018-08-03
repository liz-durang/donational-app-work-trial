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
#  giving_challenges                           :string           default([]), is an Array
#  reasons_why_i_choose_an_organization        :string           default([]), is an Array
#  contribution_frequency                      :string
#  portfolio_diversity                         :integer
#

class Donor < ApplicationRecord
  has_many :selected_portfolios, -> { where(deactivated_at: nil)}
  has_many :portfolios, through: :selected_portfolios
  has_many :payment_methods
  # Partner administrator
  has_and_belongs_to_many :partners
  has_many :partner_affiliations
  has_many :recurring_contributions

  enum portfolio_diversity: { focused: 1, mixed: 2, broad: 3 }

  extend Enumerize
  enumerize :contribution_frequency,
            in: %w[never once monthly quarterly annually],
            predicates: true

  before_create :generate_username

  def generate_username(conflict_resolving_suffix: nil)
    return if username.present?

    candidate_username = [name, conflict_resolving_suffix].compact.join('-').parameterize

    if candidate_username.blank? || Donor.exists?(username: candidate_username)
      generate_username(conflict_resolving_suffix: SecureRandom.uuid[0..6])
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

  def contribution_frequency
    super || 'monthly'
  end
end
