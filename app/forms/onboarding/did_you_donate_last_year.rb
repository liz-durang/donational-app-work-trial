module Onboarding
  class DidYouDonateLastYear < QuickResponseStep
    section "Your giving history"

    message "Did you make any donations to charity within the last 12 months?"

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No'

    display_as :radio_buttons

    follow_up_message -> (response) do
      case response
      when :yes
        "That's great!"
      when :no
        "That's okay, now is the perfect time to start."
      end
    end

    def save
      Donors::UpdateDonor.run!(
        donor: donor,
        donated_prior_year:
          case response
          when :yes
            true
          when :no
            false
          end
      )
    end

    def children
      case response
      when :yes
        [Onboarding::SatisfiedWithAmountDonatedLastYear.new(donor)]
      else
        []
      end
    end
  end
end
