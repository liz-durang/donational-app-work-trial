module Onboarding
  class HowMuchWillYouContribute < QuickResponseStep
    section "Your giving goals"

    message "Now for a harder question..."
    message "We, at Donational, believe a pledge of income helps donors intuitively understand " +
            "how much they can give to causes that matter to them."
    message 'As a percentage of your pre-tax income, how much do you want to contribute?'

    display_as :slider

    allowed_response 0.0025, '0.1%'
    allowed_response 0.0025, '0.25%'
    allowed_response 0.005, '0.5%'
    allowed_response 0.005, '0.75%'
    allowed_response 0.01, '1%'
    allowed_response 0.015, '1.5%'
    allowed_response 0.02, '2%'
    allowed_response 0.03, '3%'
    allowed_response 0.04, '4%'
    allowed_response 0.05, '5%'
    allowed_response 0.1, '10%'

    def save
      Donors::UpdateDonor.run!(donor: donor, donation_rate: response)
    end
  end
end
