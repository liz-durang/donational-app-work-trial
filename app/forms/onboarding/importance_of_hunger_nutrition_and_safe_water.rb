module Onboarding
  class ImportanceOfHungerNutritionAndSafeWater < QuickResponseStep
    section "What's important to you"

    subtitle "Hunger, nutrition, and access to safe drinking water"

    allowed_response 1, "I have other priorities"
    allowed_response 2, "Not important"
    allowed_response 3, "A tiny bit important"
    allowed_response 4, "Somewhat important"
    allowed_response 5, "Important"
		allowed_response 6, "Very important"
		allowed_response 7, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, hunger_nutrition_and_safe_water: response)
    end
  end
end
