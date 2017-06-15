# A question in a conversational form
#
# Responses to the question can be processed/persisted by providing an `on_save` Proc
#
# Example:
#     Question.new(
#       preamble: ['Hi', 'Welcome to Donational'],
#       title: 'What is your name?',
#       on_save: lambda do |response|
#         # do_some_pre_processing
#         Donor.update(first_name: response)
#       end
#     )
class Question
  include ActiveModel::Model

  attr_accessor :preamble,
                :title,
                :type,
                :on_save,
                :answer

  def save(response)
    return false unless valid?(response)

    self.answer = response if on_save.call(response)
  end

  def valid?(response)
    true
  end

  def answered?
    answer.present?
  end
end
