class SignupChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_donor

    @wizard = ContributionWizard.new
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def start
    broadcast_question(question: @wizard.first_question)
  end

  def respond(data)
    # outcome = Question.find(data: form_id).save(data[:form_data])
    # if outcome.success?
    #   prev_response_html = render: 'answers/answer', locals: { type: form.type, success: true }
    #   current_question_html = render_next_question
    question = @wizard.current_question

    if question.save(data['response'])
      broadcast_question(question: @wizard.next_question, previous_question: question)
    else
      broadcast_question(question: question)
    end
  end

  private

  def broadcast_question(question:, previous_question: nil)
    self.class.broadcast_to(
      current_donor,
      question: render(question),
      previous_question: render(previous_question)
    )
  end

  def render(question)
    return '' unless question

    ApplicationController.renderer.render(
      partial: 'conversations/question',
      locals: { question: question }
    )
  end
end
