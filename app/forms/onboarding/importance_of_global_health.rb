module Onboarding
  class ImportanceOfGlobalHealth < QuickResponseStep
    section "What's important to you"

    message "I'd like to know what issue areas matter most to you. On a scale from 1-5, how important are the following issues:"
    message "Global health"

    allowed_response 1, "Least important"
    allowed_response 2, "Not very important"
    allowed_response 3, "Somewhat important"
    allowed_response 4, "Very important"
    allowed_response 5, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, global_health: response)
    end
  end
end
