module Onboarding
  class SatisfiedWithAmountDonatedLastYear < QuickResponseStep
    section "Your giving history"

    message 'Were you satisfied with how much you donated?'

    allowed_response :satisfied, 'Yes'
    allowed_response :gave_too_much, 'I gave too much'
    allowed_response :did_not_give_enough, "I wish I had given more"

    display_as :radio_buttons

    def save
      Donors::UpdateDonor.run!(donor: donor, satisfaction_with_prior_donation: response)
    end

    follow_up_message -> (response) do
      case response
      when :satisfied
        "Perfect! We'll make sure you keep contributing an amount that feels right to you."
      when :gave_too_much
        "That's ok, we can help you stick to your budget this year."
      when :did_not_give_enough
        "That's ok, we can help you give an amount that matches your desire to make an impact."
      end
    end
  end
end
