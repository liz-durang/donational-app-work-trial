module Onboarding
  class AreYouReady < QuickResponseStep
    message "Hi!"
    message "You've just taken the first step to be more deliberate about how you donate to charity!!!"
    message "It's a simple process, and I'll ask some questions that help you uncover what type of impact (and how much!) you want to make on the world."

    allowed_response :yes, "Let's get started!"

    display_as :radio_buttons

    def save
      true
    end
  end
end
