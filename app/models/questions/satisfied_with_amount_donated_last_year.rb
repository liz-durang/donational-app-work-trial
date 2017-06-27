module Questions
  class SatisfiedWithAmountDonatedLastYear < MultipleChoiceQuestion
    message 'Were you satisfied with how much you gave?'

    allowed_response :satisfied, 'Yes'
    allowed_response :gave_too_much, 'No, I gave more than I could afford'
    allowed_response :not_enough, "No, I didn't give as much as I should have"

    def save(response)
      Rails.logger.info(response)
      true
    end

    def coerce(raw_value)
      raw_value.to_sym if raw_value.in?(allowed_responses.keys.map(&:to_s))
    end

    def follow_up_message
      case response
      when :satisfied
        "Perfect! We'll make sure you keep making the contribution that you feel you ought to"
      when :gave_too_much
        "That's ok, we can help you stick to your budget this year"
      when :not_enough
        "That's ok, we can ensure that give what you feel you should"
      end
    end
  end
end
