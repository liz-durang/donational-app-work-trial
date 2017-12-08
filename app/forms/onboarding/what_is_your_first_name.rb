module Onboarding
  class WhatIsYourFirstName < Step
    section "Let's get started"

    message "What's your first name?"

    display_as :text

    def save
      Donors::UpdateDonor.run!(donor, first_name: response)
    end
  end
end
