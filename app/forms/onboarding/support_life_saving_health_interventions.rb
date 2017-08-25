module Onboarding
  class SupportLifeSavingHealthInterventions < QuickResponseStep
    section 'Your Values: Life saving health interventions'

    message 'Malaria is one of the leading killers of children and pregnant women in Africa. Distributing insecticide-treated nets is a cheap and highly effective method of protecting children and families from the disease.'
    message "For less than $5, a net can protect 2 people for up to 4 years. For every 100-1000 nets, a child's life is saved."
    message "Other health interventions, like deworming (to treat parasatic infections) are similarly cost effective, keeping children in school and their family members from needing to skip work to look after them."
    message 'Do you want your portfolio to include organizations deliver simple, cost effective health inteventions that save and improve lives?'

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No, I have other priorities'

    display_as :radio_buttons

    def save
      true
    end

    def children
      case response
      when :yes
        [
          Onboarding::IncludeAnimalSufferingAdvocacyOrganizations.new(donor),
          Onboarding::IncludeOrganizationsDevelopingNonAnimalFoodAlternatives.new(donor)
        ]
      else
        []
      end
    end

  end
end

# http://effective-altruism.com/ea/10o/why_animals_matter_for_effective_altruism/
