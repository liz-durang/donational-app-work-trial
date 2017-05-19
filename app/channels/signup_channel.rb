class SignupChannel < ApplicationCable::Channel
  delegate :session, to: :connection

  def subscribed
    stream_for current_donor
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def start
    broadcast_question(question: questions.first)
  end

  def respond(data)
    # outcome = Question.find(data: form_id).save(data[:form_data])
    # if outcome.success?
    #   prev_response_html = render: 'answers/answer', locals: { type: form.type, success: true }
    #   current_question_html = render_next_question
    question = current_question
    question.save(data['response'])

    broadcast_question(question: next_question, previous_question: question)
  end

  # dont allow the clients to call those methods
  protected :session

  private

  def current_question
    @current_question_id ||= 0
    questions[@current_question_id]
  end

  def next_question
    return nil if last_question?

    @current_question_id += 1
    questions[@current_question_id]
  end

  def last_question?
    @current_question_id == questions.size - 1
  end

  def broadcast_question(question: question, previous_question: nil)
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

  def questions
    @questions ||=
      [
        Question.new(
          title: 'What is your name',
          on_save: lambda do |response|
            logger.info(response)
            true
          end
        ),
        Question.new(
          preamble: [
            'Donational withdraws a single monthly contribution from your account, and distributes it to your chosen charities.',
            "We'll help you choose charities that are impactful, efficient and align with your values, but first...",
            'time to make a commitment!'
          ],
          title: 'As a percentage of your annual income, how much do you want to contribute to charities?',
          on_save: lambda do |response|
            logger.info(response)
            true
          end
        ),
        Question.new(
          title: 'Does this work?',
          on_save: lambda do |response|
            logger.info(response)
            true
          end
        )
      ]
  end
end
