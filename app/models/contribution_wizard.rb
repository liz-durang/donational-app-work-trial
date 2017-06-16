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
        MultipleChoiceQuestion.new(
          preamble: [
            "Hi! You've just taken the first step to be more deliberate about how you donate to charity!!!",
            "Awesome!",
            "I'll be guiding you through the rest of the steps. \
             It's a simple process, and I'll ask some questions that help you uncover what type of impact (and how much!) you want to make on the world."
          ],
          title: "Are you ready to get started?",
          allowed_responses: ['Yes!', 'Of course!'],
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        MultipleChoiceQuestion.new(
          preamble: [
            "Great!",
            "Being deliberate is about aligning our actions with what we actually believe.",
            "We'll be exploring some questions to uncover what is important to you.",
            "First up, let's think about the obligations that we have as individuals in our society"
          ],
          title: 'As a percentage of pre-tax income, how much do you believe an individual should give to charity?',
          allowed_responses: %w(0.5% 1% 1.5% 2% 2.5% 3% 3.5% 4% 4.5% 5% 10%),
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        MultipleChoiceQuestion.new(
          preamble: ['Did you know that the average American gives 2.8% of their pretax annual income to charity?'],
          title: 'Does that surprise you?',
          allowed_responses: ['Yes', 'A little bit', 'Not at all!'],
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        MultipleChoiceQuestion.new(
          preamble: [
            "You're doing great, but now for a harder question:",
          ],
          title: 'As a percentage of your pre-tax income, how much do YOU want to contribute?',
          allowed_responses: %w(0.5% 1% 1.5% 2% 2.5% 3% 3.5% 4% 4.5% 5% 10%),
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
        Question.new(
          preamble: [
            "There's one more thing we'll need to help you make regular contributions that match what you think you *ought* to give.",
          ],
          title: "What's your (pre-tax) annual income?",
          on_save: lambda do |response|
            Rails.logger.info(response)
            true
          end
        ),
      ]
  end
end
