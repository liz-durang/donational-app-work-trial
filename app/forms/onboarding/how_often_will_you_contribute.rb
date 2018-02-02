module Onboarding
  class HowOftenWillYouContribute < QuickResponseStep
    section "Your giving goals"

    message "Regular giving helps you stick to your giving goals. "
    message "A regular flow of donations (as opposed to lump-sum contributions) " +
            "will also help charities manage their cash flow and plan more efficiently."
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
