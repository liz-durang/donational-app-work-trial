# A question in a conversational form
#
# Example:
#     class WhatIsYourName < Question
#       message 'Hi'
#       message 'What is your name?'
#
#       def save
#         # do_some_pre_processing
#         Donor.update(first_name: response)
#       end
#     end
class Question < Node
  attr_reader :response

  include ActiveModel::Model

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

  def self.follow_up_message(proc_or_string)
    @follow_up_message = proc_or_string
  end

  def self.follow_up_message_for(response)
    return @follow_up_message.call(response) if @follow_up_message.respond_to?(:call)

    @follow_up_message
  end

  def follow_up_message
    self.class.follow_up_message_for(response)
  end

  def process!(raw_value)
    response_for_rollback = response
    self.response = raw_value

    if valid?
      save
    else
      @response = response_for_rollback
    end
  end

  def self.response_type(type)
    define_method :response_type do
      type
    end
  end

  def response=(raw_value)
    @response = case response_type
                when :integer
                  raw_value.to_i
                when :float
                  raw_value.to_f
                when :currency
                  raw_value.gsub(/[^0-9\.]/, '').to_f
                when :symbol
                  raw_value.to_s.to_sym
                else
                  raw_value
                end
  end
end
