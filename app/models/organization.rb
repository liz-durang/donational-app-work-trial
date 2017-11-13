# == Schema Information
#
# Table name: organizations
#
#  ein              :string           not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  local_impact     :boolean
#  global_impact    :boolean
#  immediate_impact :boolean
#  long_term_impact :boolean
#  description      :text
#  cause_area       :string
#

# A charity of non-profit organization
class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :grants, foreign_key: 'organization_ein'
  has_many :donations

  validates :ein, presence: true
  validates :name, presence: true

  extend Enumerize
  enumerize :cause_area, in: %w[
    poverty_alleviation
    hunger_and_nutrition
    clean_water_and_sanitation
    global_health
    animal_suffering
    women_and_reproductive_rights
    economic_development
    criminal_justice
    refugees_and_immigration
    arts_and_community
    community_development
    human_rights
    veterans_affairs
    ai_and_cyber_security
    us_tax_policy
    climate_and_environment
    arts_and_community
    human_rights
    veterans_affairs
  ]
end
