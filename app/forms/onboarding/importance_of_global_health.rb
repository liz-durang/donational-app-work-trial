module Onboarding
  class ImportanceOfGlobalHealth < QuickResponseStep
    section "What's important to you"

    message "I'd like to know what issue areas matter most to you. We'll use this to decide which charities to include in your portfolio"
    message "On a scale from 1-7, how important are the following issues:"
    subtitle "Global health"

    allowed_response 1, "I have other priorities"
    allowed_response 2, "Not important"
    allowed_response 3, "A tiny bit important"
    allowed_response 4, "Somewhat important"
    allowed_response 5, "Important"
		allowed_response 6, "Very important"
		allowed_response 7, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, global_health: response)
    end
  end
end
