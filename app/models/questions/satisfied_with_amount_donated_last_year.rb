module Questions
  class SatisfiedWithAmountDonatedLastYear < MultipleChoiceQuestion
    message 'Were you satisfied with how much you gave?'

    allowed_response 'Yes'
    allowed_response 'No, I gave more than I could afford'
    allowed_response "No, I didn't give as much as I should have"

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
