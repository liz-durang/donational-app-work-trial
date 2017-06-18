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
    question = @wizard.current_question

    if question.save(data['response'])
      broadcast_question(question: @wizard.next_question, previous_response: question.response)
    else
      broadcast_question(question: question)
    end
  end

  private

  def broadcast_question(question:, previous_response: nil)
    self.class.broadcast_to(
      current_donor,
      messages: question.messages,
      previous_response: previous_response,
      possible_responses: render_responses(question)
    )
  end

  def render_responses(question)
    return '' unless question

    ApplicationController.renderer.render(
      partial: 'conversations/responses',
      locals: { question: question }
    )
  end
end
