module Questions
  class AreYouReady < MultipleChoiceQuestion
    message "Hi! You've just taken the first step to be more deliberate about how you donate to charity!!!"
    message "Awesome!"
    message "I'll be guiding you through the rest of the steps. It's a simple process, and I'll ask some questions that help you uncover what type of impact (and how much!) you want to make on the world."
    message "Are you ready to get started?"

    allowed_response 'Yes!'
    allowed_response 'Of course!'

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
