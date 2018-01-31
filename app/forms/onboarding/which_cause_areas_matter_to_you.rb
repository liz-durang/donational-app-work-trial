module Onboarding
  class WhichCauseAreasMatterToYou < QuickResponseStep
    section "What's important to you"

    message "I'd like to know what issue areas matter most to you? We'll use this to decide which charities to include in your portfolio"

    allowed_response :global_health, "Global health"
    allowed_response :poverty_and_income_inequality, "Poverty and income inequality"
    allowed_response :climate_and_environment, "Climate and the environment"
    allowed_response :animal_welfare, "Animal Welfare"
    allowed_response :hunger_nutrition_and_safe_water, "Hunger, nutrition and safe water"
    allowed_response :immigration_and_refugees, "Immigration and refugees"
    allowed_response :women_and_girls, "Women and girls"
    allowed_response :criminal_justice, "Criminal justice"

    display_as :tags

    validates :response, presence: true

    def save
      relevances = Organization::CAUSE_AREAS.map(&:to_sym).map do |cause_area|
        [cause_area, cause_area.in?(response) ? 7 : 0]
      end.to_h

      Donors::UpdateCauseAreaRelevance.run!(donor, relevances)
    end
  end
end
