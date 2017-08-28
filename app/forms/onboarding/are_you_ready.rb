module Onboarding
  class AreYouReady < QuickResponseStep
    section "Let's get started"

    message "Hi!"
    message "You've taken the first step to be *deliberate* about the way you donate to charity!!!"
    message "We'll start by uncovering what type of impact (and how much!) you want to make on the world."

    allowed_response :yes, "Let's get started!"

    display_as :radio_buttons

    def save
      true
    end
  end
end
