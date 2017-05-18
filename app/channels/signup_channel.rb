class SignupChannel < ApplicationCable::Channel
  delegate :session, to: :connection

  def subscribed
    stream_for current_donor

    self.class.broadcast_to(
      current_donor,
      success: true,
      previous_question_html: '',
      previous_answer_html: '',
      question_html: 'What is your name?',
      responses_html: '<input type="text"/>'
    )
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def submit_question(data)
    # outcome = Question.find(data: form_id).save(data[:form_data])
    # if outcome.success?
    #   prev_response_html = render: 'answers/answer', locals: { type: form.type, success: true }
    #   current_question_html = render_next_question
    sleep 1

    self.class.broadcast_to(
      current_donor,
      success: true,
      previous_question_html: 'What is your name?',
      previous_answer_html: data['answer'],
      question_html: 'And how old are you?',
      responses_html: '<input type="text"/>'
    )
  end

  # dont allow the clients to call those methods
  protected :session
end
