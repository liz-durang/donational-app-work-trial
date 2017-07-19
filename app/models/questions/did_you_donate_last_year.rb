module Questions
  class DidYouDonateLastYear < MultipleChoiceQuestion
    message "Did you make any donations to charity within the last 12 months?"

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No'

    response_type :symbol

    follow_up_message -> (response) do
      case response
      when :yes
        "That's great!"
      when :no
        "That's okay, now is the perfect time to start. We'll help you select charities " +
        "that do the most good, and decide on an amount to donate that fits in with your " +
        "budget and financial plans."
      end
    end

    def save
      true
    end

    def children
      case response
      when :yes
        [Questions::SatisfiedWithAmountDonatedLastYear.new]
      else
        []
      end
    end
  end
end
