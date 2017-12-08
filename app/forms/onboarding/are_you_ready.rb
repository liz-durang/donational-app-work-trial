module Onboarding
  class AreYouReady < QuickResponseStep
    section "Let's get started"

    message "Hi!"
    message "You've taken the first step to be *deliberate* about the way you donate to charity!!!"
    message "I'm going to help you build a charitable portfolio based on what matters most to you."

    allowed_response :yes, "Let's get started!"

    display_as :radio_buttons

    def save
      true
    end
  end
end
