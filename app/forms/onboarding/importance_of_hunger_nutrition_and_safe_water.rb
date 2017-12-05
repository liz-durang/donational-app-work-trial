module Onboarding
  class ImportanceOfHungerNutritionAndSafeWater < QuickResponseStep
    section "What's important to you"

    message "Hunger, nutrition, and access to safe drinking water"

    allowed_response 1, "Least important"
    allowed_response 2, "Not very important"
    allowed_response 3, "Somewhat important"
    allowed_response 4, "Very important"
    allowed_response 5, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, hunger_nutrition_and_safe_water: response)
    end
  end
end
