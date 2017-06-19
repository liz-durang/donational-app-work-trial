class MultipleChoiceQuestion < Question
  # DSL method
  def self.allowed_response(m)
    @allowed_responses ||= []
    @allowed_responses << m
  end

  def self.allowed_responses
    @allowed_responses
  end

  def allowed_responses
    self.class.allowed_responses
  end

  def valid?(response)
    return false unless allowed_responses.include?(response)
    super
  end
end
