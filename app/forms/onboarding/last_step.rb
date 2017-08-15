module Onboarding
  class LastStep < QuickResponseStep
    message "Thanks! Now it's time to take a look at your charity portfolio"

    allowed_response :create, 'Create my portfolio'

    display_as :radio_buttons

    def save
      true
    end
  end
end
