module Onboarding
  class WhatIsYourFirstName < Step
    section "Let's get started"

    message "Let's start by getting to know a little about you."
    message "What's your first name?"

    follow_up_message -> (response) do
      "Welcome #{response}!"
    end

    display_as :text

    def save
      Donors::UpdateDonor.run!(donor, first_name: response)
    end

    def prepopulated_value
      donor.first_name
    end
  end
end
