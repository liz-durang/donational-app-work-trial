# frozen_string_literal: true

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
#  entity_name                                 :string
#  title                                       :string
#  house_name_or_number                        :string
#  postcode                                    :string
#  uk_gift_aid_accepted                        :boolean          default(FALSE), not null
#

class Donor < ApplicationRecord
  searchkick word_start: [:name], batch_size: 1000, callbacks: :async

  def search_data
    {
      email: email,
      name: name,
      partner_id: Partners::GetPartnerForDonor.call(donor: self).id
    }
  end
  
  self.primary_key = 'id'

  def self.search_for(query, limit: 10)
    self.search(query, limit: limit, misspellings: { prefix_length: 2 }, match: :word_start)
  end
  has_many :selected_portfolios, -> { where(deactivated_at: nil) }
  has_many :portfolios, through: :selected_portfolios
  has_many :payment_methods
  # Partner administrator
  has_and_belongs_to_many :partners
  has_many :partner_affiliations
  has_many :recurring_contributions

  with_options if: :uk_gift_aid_accepted do
    validates :title, presence: true, length: { maximum: 4 }
    validates :first_name, presence: true, length: { maximum: 35 }
    validates :last_name, presence: true, length: { maximum: 35 }
    validates :house_name_or_number, presence: true # TODO: Change to street_address
    validates :postcode, presence: true, format: {
      with: /\A([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? [0-9][A-Za-z]{2}|[Gg][Ii][Rr] 0[Aa]{2})\z/,
      message: 'must include a space e.g. AA1 3DD'
    }
  end

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
    entity_name || [first_name, last_name].compact.join(' ')
  end

  def last_name_initial
    last_name.first + '.' if last_name.present?
  end

  def anonymized_name
    entity_name || [first_name, last_name_initial].compact.join(' ')
  end

  def short_name
    person? ? first_name : entity_name
  end

  def entity?
    entity_name.present?
  end

  def person?
    !entity?
  end

  def account_holder?
    email.present?
  end

  def contribution_frequency
    super || 'monthly'
  end

  def time_zone
    'Eastern Time (US & Canada)'
  end
end
