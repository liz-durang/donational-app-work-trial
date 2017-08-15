module Onboarding
  class SatisfiedWithAmountDonatedLastYear < QuickResponseStep
    message 'Were you satisfied with how much you gave?'

    allowed_response :satisfied, 'Yes'
    allowed_response :gave_too_much, 'No, I gave more than I could afford'
    allowed_response :did_not_give_enough, "No, I didn't give as much as I should have"

    display_as :radio_buttons

    def save
      Donors::UpdateDonor.run!(donor, satisfaction_with_prior_donation: response)
    end

    def follow_up_message
      case response
      when :satisfied
        "Perfect! We'll make sure you keep making the contribution that you feel you ought to"
      when :gave_too_much
        "That's ok, we can help you stick to your budget this year"
      when :did_not_give_enough
        "That's ok, we can ensure that give what you feel you should"
      end
    end
  end
end
