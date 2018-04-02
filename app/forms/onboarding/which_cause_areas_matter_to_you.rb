module Onboarding
  class WhichCauseAreasMatterToYou < QuickResponseStep
    section "What's important to you"

    message "I'd like to know what cause areas matter most to you. We'll use this to decide which charities to include in your portfolio"

    allowed_response :global_health, "Global health"
    allowed_response :poverty_and_income_inequality, "Poverty and income inequality"
    allowed_response :climate_and_environment, "Climate and the environment"
    allowed_response :animal_welfare, "Animal welfare"
    allowed_response :hunger_nutrition_and_safe_water, "Hunger, nutrition and safe water"
    allowed_response :immigration_and_refugees, "Immigration and refugees"
    allowed_response :women_and_girls, "Women and girls"
    allowed_response :criminal_justice, "Criminal justice"

    display_as :tags

    validates :response, presence: true

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor: donor, causes_that_matter: response)
    end
  end
end
