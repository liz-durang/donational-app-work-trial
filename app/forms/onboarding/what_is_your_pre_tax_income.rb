module Onboarding
  class WhatIsYourPreTaxIncome < Step
    section "Your giving goals"

    message "To calculate your monthly contribution, we'll need to know about how much you earn."
    message "What is your (pre-tax) annual income?"
    subtitle "(we'll keep this private and secure)"

    display_as :currency

    validates :response, numericality: { greater_than_or_equal_to: 0, only_integer: true }

    def save
      Donors::UpdateDonor.run!(donor, annual_income_cents: response)
    end
  end
end
