module Onboarding
  class WhatIsYourPreTaxIncome < Step
    section "Your giving goals"

    message "To relate your donations to your income, we'll need to know how much you earn."
    message "What is your pre-tax annual income?"

    display_as :currency

    validates :response, numericality: { greater_than_or_equal_to: 0, only_integer: true }

    def save
      Donors::UpdateDonor.run!(donor: donor, annual_income_cents: response)
    end
  end
end
