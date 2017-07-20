class MultipleChoiceQuestion < Question
  response_type :symbol

  validate :inclusion_in_allowed_responses

  # DSL method
  def self.allowed_response(value, text=nil)
    text ||= value.to_s
    @allowed_responses ||= {}
    @allowed_responses[value] = text
  end

  def self.allowed_responses
    @allowed_responses
  end

  def allowed_responses
    self.class.allowed_responses
  end

  def inclusion_in_allowed_responses
    return if response.in?(allowed_responses.keys)

    errors.add(:response, "#{response} is not one of the allowed responses")
  end
end
