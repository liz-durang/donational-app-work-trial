module Onboarding
  class PrimaryReasons < QuickResponseStep
    section "Let's get started"

    message 'What are the main things that you are looking for?'

    allowed_response :alignment_with_beliefs,
      'I want to discover charities that align with my values',
      "We'll help you choose charities that make a difference in cause areas that you care about"
    allowed_response :most_impact,
      'I want to donate to charities that have the most impact',
      "We've consulted with experts to select charities that have the greatest impact per each dollar donated."
    allowed_response :share_with_others,
      'I want to inspire others to give',
      "You can share your charity portfolio with others, encouraging your friends to donate to causes that matter to you"
    allowed_response :manage_donations,
      'I want to manage all of my donations from one place (and make my life simpler at tax-time)',
      "Your contributions through Donational are automatically pooled with other donations to minimize fees. At the end of the year, we'll send you a charitable giving receipt to help you do your taxes."

    display_as :checkboxes

    def save
      true
    end

    def follow_up_message
      case response
      when :todo
        "Good answer!"
      end
    end
  end
end
