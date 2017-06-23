class SignupChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_donor

    @wizard = Wizard.new([
      Questions::AreYouReady.new,
      Questions::DidYouDonateLastYear.new,
      Questions::SatisfiedWithAmountDonatedLastYear.new,
      Questions::HowMuchShouldAnIndividualGive.new,
      Questions::DoYouKnowTheAverageContribution.new,
      Questions::HowMuchWillYouContribute.new,
      Questions::WhatIsYourPreTaxIncome.new,
      Questions::LocalOrGlobalImpact.new,
      Questions::ImmediateOrLongTerm.new,
      Questions::ComingSoon.new
      # Large vs Small charities
      # Cause areas
        #! We'll go through and choose causes that are important to you to add to your charity portfolio
        #! You'll be able to adjust how much to allocate to each cause area, but first,
        #! let's get an idea of which causes resonate with you
        # Climate change and the Environment
        # Education
        # Poverty action
        # Health related causes
        # Disaster relief
        # Clean water
        # Human rights
      # Any specific health related causes (cancer research, alzheimers)
      # Any specific causes that want to add to your portfolio
        # Donational chooses highly impact charities, but we know there are pet-causes
      # Self-actualization/autonomy (charities that promote... in contrast to just )
    ])
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def start
    broadcast_step(step: @wizard.first_step)
  end

  def respond(data)
    step = @wizard.current_step

    if step.process!(data['response'])
      broadcast_step(step: @wizard.next_step!, previous_response: step.formatted_response)
    else
      broadcast_step(step: step)
    end
  end

  private

  def broadcast_step(step:, previous_response: nil)
    self.class.broadcast_to(
      current_donor,
      messages: step.messages,
      previous_response: previous_response,
      possible_responses: render_responses(step)
    )
  end

  def render_responses(step)
    return '' unless step

    ApplicationController.renderer.render(
      partial: 'conversations/responses',
      locals: { step: step }
    )
  end
end
