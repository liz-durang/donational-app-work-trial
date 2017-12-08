module Onboarding
  class ImportanceOfImmigrationAndRefugees < QuickResponseStep
    section "What's important to you"

    subtitle "Immigration and Refugees"

    allowed_response 1, "Least important"
    allowed_response 2, "Not very important"
    allowed_response 3, "Somewhat important"
    allowed_response 4, "Very important"
    allowed_response 5, "Most important"

    display_as :scale

    def save
      Donors::UpdateCauseAreaRelevance.run!(donor, immigration_and_refugees: response)
    end
  end
end
