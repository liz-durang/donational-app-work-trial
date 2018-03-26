module Onboarding
  class ImmediateOrLongTerm < QuickResponseStep
    section 'Your values: Immediate vs Long-term'

    message 'We have carefully selected charities that have a high impact. The lives of those who need it most *will* be changed through your contributions, but we need your help to choose when.'
    message 'Some charities have an immediate impact, for example:'
    message 'disaster relief, providing food and clean drinking water, or life saving health interventions'
    message 'Other organizations focus on research and policy change, which if successful are likely to have a large impact in the long-term.'
    message 'When it comes to your portfolio, how would you like to focus the impact?'

    allowed_response :immediate, 'Immediate impact'
    allowed_response :both, 'A mix of immediate and long-term impact'
    allowed_response :long_term, 'Long-Term impact'

    display_as :radio_buttons

    def save
      case response
      when :immediate
        Donors::UpdateDonor.run!(
          donor: donor,
          include_immediate_impact_organizations: true,
          include_long_term_impact_organizations: false
        )
      when :both
        Donors::UpdateDonor.run!(
          donor: donor,
          include_immediate_impact_organizations: true,
          include_long_term_impact_organizations: true
        )
      when :long_term
        Donors::UpdateDonor.run!(
          donor: donor,
          include_immediate_impact_organizations: false,
          include_long_term_impact_organizations: true
        )
      end
    end
  end
end
