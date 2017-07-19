module Onboarding
  class WhatIsYourPreTaxIncome < Question
    message "By making regular contributions that are tied to your income"
    message "a) you can feel great knowing that you're always giving exactly as much as you believe you *ought* to give."
    message "b) charities receive donations regularly (as opposed to larger lump sum payments), which helps them to manage their cash flow and plan more efficiently"
    message "To calculate your monthly contribution, we'll need to know about how much you earn."
    message "What's your (pre-tax) annual income?"

    response_type :currency

    def save
      Rails.logger.info(response)
      true
    end
  end
end
