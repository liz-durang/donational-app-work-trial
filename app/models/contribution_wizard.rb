# Onboarding wizard to collect a users contribution preferences
class ContributionWizard
  def initialize
    @current_question_id = 0
  end

  def first_question
    questions.first
  end

  def last_question
    questions.last
  end

  def current_question
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

  def questions
    @questions ||=
      [
        Question.new(
          title: 'What is your name',
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        MultipleChoiceQuestion.new(
          preamble: [
            'Donational withdraws a single monthly contribution from your account, and distributes it to your chosen charities.',
            "We'll help you choose charities that are impactful, efficient and align with your values, but first...",
            'time to make a commitment!'
          ],
          allowed_responses: %w(0.25% 0.5% 1% 2% 3% 4% 5% 10%),
          title: 'As a percentage of your annual income, how much do you want to contribute to charities?',
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        MultipleChoiceQuestion.new(
          title: 'Does this work?',
          allowed_responses: [:yes, :no],
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        )
      ]
  end
end
