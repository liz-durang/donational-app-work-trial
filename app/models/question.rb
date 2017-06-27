# A question in a conversational form
#
# Example:
#     class WhatIsYourName < Question
#       message 'Hi'
#       message 'What is your name?'
#
#       def save(response)
#         # do_some_pre_processing
#         Donor.update(first_name: response)
#       end
#     end
class Question < Node
  attr_accessor :response

  # DSL method
  def self.message(m)
    @messages ||= []
    @messages << m
  end

  def self.messages
    @messages
  end

  def messages
    self.class.messages
  end

  def process!(raw_value)
    value = coerce(raw_value)
    return false unless valid?(value)

    self.response = value if save(value)
  end

  def valid?(value)
    true
  end

  def coerce(raw_value)
    raw_value
  end

  def follow_up_message
  end
end
