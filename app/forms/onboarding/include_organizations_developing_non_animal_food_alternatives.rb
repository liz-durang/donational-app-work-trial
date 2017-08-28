module Onboarding
  class IncludeOrganizationsDevelopingNonAnimalFoodAlternatives < QuickResponseStep
    section "Your Values: Reducing Animal Suffering"

    message 'Do you want your portfolio to include organizations that use the latest food science technology to develop non-animal-based meat, dairy, and eggs alternatives, to reduce demand for factory farmed animals?'

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No'

    display_as :radio_buttons

    def save
      true
    end
  end
end
