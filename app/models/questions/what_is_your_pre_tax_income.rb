module Questions
  class WhatIsYourPreTaxIncome < Question
    message "There's one more thing we'll need to help you make regular contributions that match what you think you *ought* to give."
    message "What's your (pre-tax) annual income?"

    def save(response)
      Rails.logger.info(response)
      true
    end
  end
end
