module Onboarding
  class ImportanceOfPovertyAndIncomeInequality < QuickResponseStep
    section "What's important to you"

    subtitle "Poverty and income inequality"

    allowed_response 1, "I have other priorities"
    allowed_response 2, "Not important"
    allowed_response 3, "A tiny bit important"
    allowed_response 4, "Somewhat important"
    allowed_response 5, "Important"
		allowed_response 6, "Very important"
		allowed_response 7, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, poverty_and_income_inequality: response)
    end
  end
end
