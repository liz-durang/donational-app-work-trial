module Questions
  class DidYouDonateLastYear < MultipleChoiceQuestion
    message "Did you make any donations to charity within the last 12 months?"

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No'

    def save(response)
      Rails.logger.info(response)
      true
    end

    def coerce(raw_value)
      return :yes if raw_value == 'yes'
      :no
    end

    def follow_up_message
      case response
      when :yes
        "That's great!"
      when :no
        "That's okay, now is the perfect time to start. We'll help you select charities that do the most good, and decide on an amount to donate that fits in with your budget and financial plans."
      end
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
