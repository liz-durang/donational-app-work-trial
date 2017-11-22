module Onboarding
  class WhatIsYourPreTaxIncome < Step
    message "By making regular contributions that are tied to your income"
    message "a) you can feel great knowing that you're always giving exactly as much as you believe you *ought* to give."
    message "b) charities receive donations regularly (as opposed to larger lump sum payments), which helps them to manage their cash flow and plan more efficiently"
    message "To calculate your monthly contribution, we'll need to know about how much you earn."
    message "What's your (pre-tax) annual income?"

    display_as :currency

    validates :response, numericality: { greater_than_or_equal_to: 0, only_integer: true }

    def save
      Donors::UpdateDonor.run!(donor, annual_income_cents: response)
    end
  end
end
