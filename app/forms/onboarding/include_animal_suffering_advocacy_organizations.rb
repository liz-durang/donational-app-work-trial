module Onboarding
  class IncludeAnimalSufferingAdvocacyOrganizations < QuickResponseStep
    section "Your Values: Reducing Animal Suffering"

    message 'Do you want to include organizations that advocate for better treatment of farmed animals through education, outreach, promoting vegetarianism and veganism?'

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No'

    display_as :radio_buttons

    def save
      true
    end
  end
end

# http://effective-altruism.com/ea/10o/why_animals_matter_for_effective_altruism/
