module Questions
  class DidYouDonateLastYear < MultipleChoiceQuestion
    message "Have you donated to any charities within the last year?"

    allowed_response 'Yes'
    allowed_response 'No'

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
