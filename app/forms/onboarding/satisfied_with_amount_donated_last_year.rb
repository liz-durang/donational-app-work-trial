module Onboarding
  class SatisfiedWithAmountDonatedLastYear < QuickResponseStep
    section "Your giving history"

    message 'Were you satisfied with how much you donated?'

    allowed_response :satisfied, 'Yes'
    allowed_response :gave_too_much, 'I gave too much'
    allowed_response :did_not_give_enough, "I should have donated more"

    display_as :radio_buttons

    def save
      Donors::UpdateDonor.run!(donor, satisfaction_with_prior_donation: response)
    end

    follow_up_message -> (response) do
      case response
      when :satisfied
        "Perfect! We'll make sure you keep making the contribution that you feel you ought to"
      when :gave_too_much
        "That's ok, we can help you stick to your budget this year"
      when :did_not_give_enough
        "That's ok, we can ensure that you give what you feel you should"
      end
    end
  end
end
