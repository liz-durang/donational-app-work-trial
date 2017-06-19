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
class Question
  include ActiveModel::Model

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

  def process!(response)
    return false unless valid?(response)

    self.response = response if save(response)
  end

  def valid?(response)
    true
  end

  def responded?
    response.present?
  end
end
