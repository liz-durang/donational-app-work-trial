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
#  deactivated_at   :datetime
#

# A charity of non-profit organization
class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :grants, foreign_key: 'organization_ein'
  has_many :donations

  validates :ein, presence: true
  validates :name, presence: true

  CAUSE_AREAS = %w(
    global_health
    poverty_and_income_inequality
    climate_and_environment
    animal_welfare
    hunger_nutrition_and_safe_water
    women_and_girls
    immigration_and_refugees
    economic_development
    criminal_justice
  )

  extend Enumerize
  enumerize :cause_area, in: CAUSE_AREAS

  def active?
    deactivated_at.blank?
  end
end
