module Questions
  class HowMuchWillYouContribute < MultipleChoiceQuestion
    message "You're doing great, but now for a harder question:"
    message 'As a percentage of your pre-tax income, how much do YOU want to contribute?'

    allowed_response '0.5%'
    allowed_response '1%'
    allowed_response '1.5%'
    allowed_response '2%'
    allowed_response '2.5%'
    allowed_response '3%'
    allowed_response '3.5%'
    allowed_response '4%'
    allowed_response '4.5%'
    allowed_response '5%'
    allowed_response '10%'

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
