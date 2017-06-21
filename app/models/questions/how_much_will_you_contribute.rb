module Questions
  class HowMuchWillYouContribute < MultipleChoiceQuestion
    message "You're doing great, but now for a harder question:"
    message 'As a percentage of your pre-tax income, how much do YOU want to contribute?'

    allowed_response 0.05, '0.5%'
    allowed_response 0.01, '1%'
    allowed_response 0.015, '1.5%'
    allowed_response 0.02, '2%'
    allowed_response 0.025, '2.5%'
    allowed_response 0.03, '3%'
    allowed_response 0.035, '3.5%'
    allowed_response 0.04, '4%'
    allowed_response 0.045, '4.5%'
    allowed_response 0.05, '5%'
    allowed_response 0.1, '10%'

    def save(response)
      Rails.logger.info(response)
      true
    end

    def coerce(raw_value)
      raw_value.to_f
    end
  end
end
