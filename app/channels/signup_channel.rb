class SignupChannel < ApplicationCable::Channel
  delegate :session, to: :connection

  def subscribed
    stream_for current_donor
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def start
    broadcast_question(questions.first)
  end

  def submit_question(data)
    # outcome = Question.find(data: form_id).save(data[:form_data])
    # if outcome.success?
    #   prev_response_html = render: 'answers/answer', locals: { type: form.type, success: true }
    #   current_question_html = render_next_question
    sleep 1

    question_id = data['question_id'].to_i
    question = questions[question_id]
    # response = question.save!(data['answer'])

    broadcast_question(
      questions[question_id + 1],
      previous_answer: data['answer'],
      previous_question: question
    )
  end

  # dont allow the clients to call those methods
  protected :session

  private

  def broadcast_question(question, previous_answer: nil, previous_question: nil)
    self.class.broadcast_to(
      current_donor,
      success: true,
      previous_question_html: previous_question.try(:[], :title),
      previous_answer_html: previous_answer,
      question_html: question[:title],
      responses_html: %Q(<input type="text" data-question-id="#{question[:id]}">),
    )
  end

  def questions
    [
      { id: 0, title: ['What is your name?'] },
      { id: 1, title: ['As a percentage of annual income, how much aught individuals give to charity?'] },
      { id: 2, title: [
        'Donational withdraws a single monthly contribution from your account, and distributes it to your chosen charities.',
        "We'll help you choose charities that are impactful, efficient and align with your values, but first...",
        'time to make a commitment!',
        'As a percentage of your annual income, how much do you want to contribute to charities?'
        ]
      }
    ]
  end
end
