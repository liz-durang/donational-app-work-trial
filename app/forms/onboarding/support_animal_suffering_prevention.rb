module Onboarding
  class SupportAnimalSufferingPrevention < QuickResponseStep
    section "Your Values: Reducing Animal Suffering"

    message "The world's population is over 7 billion people."
    message 'There are around 70 billion farm animals produced for food each year, with a majority raised in intense confinement, forced inhibition of natural behaviors, and slaughtered with techniques that are cheap, but cause immense pain and suffering.'
    # message 'Speciesism?'
    message 'Do you want your portfolio to include organizations that focus on reducing animal suffering?'

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
