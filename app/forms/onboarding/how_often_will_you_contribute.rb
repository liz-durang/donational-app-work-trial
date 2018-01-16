module Onboarding
  class HowOftenWillYouContribute < QuickResponseStep
    section "Your giving goals"

    message "We help you streamline your charitable giving."
    message 'Your donation will be split up across the charities and cause areas that are important to you.'
    message "By giving regularly, you can easily meet your own giving goals. How often do you like to donate?"

    display_as :radio_buttons

    allowed_response :monthly, 'Monthly'
    allowed_response :quarterly, 'Every Quarter'
    allowed_response :annually, 'Annually'
    allowed_response :once, 'Once'
    allowed_response :never, "I'm just looking"

    def save
      Donors::UpdateDonor.run!(donor, contribution_frequency: response)
    end
  end
end
