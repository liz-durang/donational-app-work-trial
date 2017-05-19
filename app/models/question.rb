class Question
  include ActiveModel::Model

  attr_accessor :preamble,
                :title,
                :allowed_responses,
                :on_save,
                :answer

  def save(response)
    self.answer = response
    on_save.call(response)
    true
  end
end
