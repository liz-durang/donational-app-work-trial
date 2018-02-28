# == Schema Information
#
# Table name: organizations
#
#  ein                   :string           not null, primary key
#  name                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  local_impact          :boolean
#  global_impact         :boolean
#  immediate_impact      :boolean
#  long_term_impact      :boolean
#  description           :text
#  cause_area            :string
#  deactivated_at        :datetime
#  mission               :text
#  context               :text
#  impact                :text
#  why_you_should_care   :text
#  website_url           :string
#  annual_report_url     :string
#  financials_url        :string
#  form_990_url          :string
#  recommended_by        :string           default([]), is an Array
#  suggested_by_donor_id :uuid
#

# A charity of non-profit organization
class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :grants, foreign_key: 'organization_ein'
  has_many :donations

  belongs_to :suggested_by_donor, class_name: 'Donor', foreign_key: 'suggested_by_donor_id', required: false

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
    education
    economic_development
    criminal_justice
    user_added_organization
  )

  extend Enumerize
  enumerize :cause_area, in: CAUSE_AREAS

  def self.recommendable_cause_areas
    CAUSE_AREAS - ['user_added_organization']
  end

  def active?
    deactivated_at.blank?
  end

  def suggested_by_donor?
    suggested_by_donor.present?
  end

  def cause_area
    super || 'user_added_organization'
  end
end
