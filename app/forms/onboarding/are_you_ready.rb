module Onboarding
  class AreYouReady < QuickResponseStep
    section "Let's get started"

    message "Hi!"
    message "I'm going to help you build a charitable portfolio based on what matters most to you."

    allowed_response :yes, "Ok, I'm ready!"

    display_as :radio_buttons

    def save
      true
    end
  end
end
