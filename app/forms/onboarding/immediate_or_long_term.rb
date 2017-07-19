module Onboarding
  class ImmediateOrLongTerm < MultipleChoiceQuestion
    message 'Some organizations focus on making an immediate impact.'
    message 'e.g. disaster relief, providing food and clean drinking water, life saving health interventions'
    message 'Other organizations focus on longer term research and policy change'
    message 'e.g. cancer research, poverty awareness'
    message 'For the charities that you support, would you prefer them to have an immediate or a long term impact?'

    allowed_response :immediate, 'Immediate'
    allowed_response :both, 'Both (a mix of immediate and long-term impact)'
    allowed_response :long_term, 'Long-Term'

    def save
      Rails.logger.info(response)
      true
    end
  end
end
