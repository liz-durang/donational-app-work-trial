module Onboarding
  class HowOftenWillYouContribute < QuickResponseStep
    section "Your giving goals"

    message "We help you streamline your charitable giving."
    message 'Your donation will be split up between the charities and cause areas that are important to you.'
    message "By making regular contributions that are tied to your income"
    message "a) you can feel great knowing that you're always giving exactly as much as you believe you *ought* to give."
    message "b) charities receive donations regularly (as opposed to larger lump sum payments), which helps them to manage their cash flow and plan more efficiently"
    message "How often would you like to donate?"

    display_as :radio_buttons

    allowed_response :monthly, 'Monthly'
    allowed_response :quarterly, 'Every Quarter'
    allowed_response :annually, 'Annually'
    allowed_response :once, 'Just this one-time'
    # allowed_response :never, "I'm just looking"

    def save
      Donors::UpdateDonor.run!(donor, contribution_frequency: response)
    end
  end
end
