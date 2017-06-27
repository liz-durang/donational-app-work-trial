module Questions
  class HowMuchWillYouContribute < MultipleChoiceQuestion
    message "With a single monthly donation, you'll ensure that you meet your own expectations about how much you should contribute to charity."
    message 'Your donation will be split up between the charities and cause areas that are important to you.'
    message "By pooling donations and by avoiding credit card fees, we're able to spend less on processing fees and get more of your money to the organization."
    message "Now for a harder question..."
    message 'As a percentage of your pre-tax income, how much do YOU want to contribute?'

    response_type :float

    allowed_response 0.005, '0.5%'
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

    def save
      Rails.logger.info(response)
      true
    end
  end
end
