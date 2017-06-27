class MultipleChoiceQuestion < Question
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

  def valid?(value)
    return false unless allowed_responses.keys.include?(value)
    super
  end
end
