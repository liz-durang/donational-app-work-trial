class MultipleChoiceQuestion < Question
  attr_accessor :allowed_responses

  def valid?(response)
    return false unless allowed_responses.include?(response)
    super
  end
end
