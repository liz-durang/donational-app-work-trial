module Questions
  class DoYouKnowTheAverageContribution < MultipleChoiceQuestion
    message 'Did you know that the average American gives 2.8% of their pretax annual income to charity?'
    message 'Does that surprise you?'

    allowed_response 'Yes'
    allowed_response 'A little bit'
    allowed_response 'Not at all!'

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
