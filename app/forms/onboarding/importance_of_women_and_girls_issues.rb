module Onboarding
  class ImportanceOfWomenAndGirlsIssues < QuickResponseStep
    section "What's important to you"

    message "Women's and girl's issues"

    allowed_response 1, "Least important"
    allowed_response 2, "Not very important"
    allowed_response 3, "Somewhat important"
    allowed_response 4, "Very important"
    allowed_response 5, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, women_and_girls: response)
    end
  end
end
