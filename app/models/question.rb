# A question in a conversational form
#
# Responses to the question can be processed/persisted by providing an `on_save` Proc
#
# Example:
#     Question.new(
#       messages: ['Hi', 'Welcome to Donational', 'What is your name?'],
#       on_save: lambda do |response|
#         # do_some_pre_processing
#         Donor.update(first_name: response)
#       end
#     )
class Question
  include ActiveModel::Model

  attr_accessor :messages,
                :type,
                :on_save,
                :response

  def save(response)
    return false unless valid?(response)

    self.response = response if on_save.call(response)
  end

  def valid?(response)
    true
  end

  def responded?
    response.present?
  end
end
