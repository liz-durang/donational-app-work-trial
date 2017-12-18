# == Schema Information
#
# Table name: cause_area_relevances
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  global_health                   :integer
#  poverty_and_income_inequality   :integer
#  climate_and_environment         :integer
#  animal_welfare                  :integer
#  hunger_nutrition_and_safe_water :integer
#  women_and_girls                 :integer
#  immigration_and_refugees        :integer
#  education                       :integer
#  economic_development            :integer
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#

class CauseAreaRelevance < ApplicationRecord
  belongs_to :donor
end
