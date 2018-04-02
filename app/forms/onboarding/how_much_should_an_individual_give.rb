module Onboarding
  class HowMuchShouldAnIndividualGive < QuickResponseStep
    section "Your impact"

    message 'As a percentage of your income, how much do you believe an individual should give to charity?'

    display_as :slider

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
      Donors::UpdateDonor.run!(donor: donor, donation_rate_expected_from_individuals: response)
    end
  end
end
