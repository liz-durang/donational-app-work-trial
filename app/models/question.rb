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
