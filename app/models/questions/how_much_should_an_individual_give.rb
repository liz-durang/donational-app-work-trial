module Questions
  class HowMuchShouldAnIndividualGive < MultipleChoiceQuestion
    message "Great!"
    message "Being deliberate is about aligning our actions with what we actually believe."
    message "We'll be exploring some questions to uncover what is important to you."
    message "First up, let's think about the obligations that we have as individuals in our society"
    message 'As a percentage of pre-tax income, how much do you believe an individual should give to charity?'

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
