module Onboarding
  class AreYouReady < QuickResponseStep
    section "Welcome to Your Charitable Advisor"

    message "Hi!"
    message "I'm going to ask you a few questions to understand what matters most to you when you give."
    message "Based on your answers, I'll recommend high-impact charities to create your personalized charitable portfolio."

    allowed_response :yes, "Ok, I'm ready!"

    display_as :radio_buttons

    def save
      true
    end
  end
end
