module Onboarding
  class HowMuchShouldAnIndividualGive < MultipleChoiceQuestion
    message "Being deliberate is about aligning our actions with what we actually believe. " +
      "We'll be exploring some questions to uncover what is important to you."
    message "First up, let's think about the obligations that we have as individuals in our society."
    message 'As a percentage of pre-tax income, how much do you believe an individual should give to charity?'

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
      Donors::UpdateDonor.run!(donor, donation_rate_expected_from_individuals: response)
    end
  end
end
