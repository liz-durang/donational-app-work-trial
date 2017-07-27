module Onboarding
  class LastStep < MultipleChoiceQuestion
    message "Thanks! Now it's time to take a look at your charity portfolio"

    allowed_response :create, 'Create my portfolio'

    def save
      true
    end
  end
end
