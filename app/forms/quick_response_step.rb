require 'ostruct'

class QuickResponseStep < Question
  validate :inclusion_in_allowed_responses

  # DSL method
  def self.allowed_response(value, text=nil, description=nil)
    @allowed_responses ||= []
    @allowed_responses << QuickResponse.new(value: value, title: text, description: description)
  end

  def self.allowed_responses
    @allowed_responses
  end

  def allowed_responses
    self.class.allowed_responses
  end

  def inclusion_in_allowed_responses
    return if Array(response).all? { |r| r.in?(allowed_responses.map(&:value)) }

    errors.add(:response, "#{response} is not one of the allowed responses")
  end

  class QuickResponse
    attr_reader :value, :title, :description

    def initialize(value:, title:, description:)
      @value = value
      @title = title || value.to_s
      @description = description
    end

    def to_param
      value.to_s.parameterize
    end
  end
end
