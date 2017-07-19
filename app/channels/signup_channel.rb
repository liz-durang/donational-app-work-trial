class SignupChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_donor

    steps = begin
      Questions::AreYouReady.new <<
      Questions::DidYouDonateLastYear.new <<
      Questions::HowMuchShouldAnIndividualGive.new <<
      Questions::DoYouKnowTheAverageContribution.new <<
      Questions::HowMuchWillYouContribute.new <<
      Questions::WhatIsYourPreTaxIncome.new <<
      Questions::LocalOrGlobalImpact.new <<
      Questions::ImmediateOrLongTerm.new <<
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
    end
    @current_step = steps
  end

  def unsubscribed
    @current_step = nil
  end

  def start
    broadcast_step(step: @current_step)
  end

  def respond(data)
    step = @current_step

    Rails.logger.info(data['response'])

    if step.process!(data['response'])
      @current_step = @current_step.next_node
      broadcast_step(step: @current_step, previous_step: step)
    else
      broadcast_step(step: step, previous_step: Questions::ErrorStep.new)
    end
  end

  private

  def broadcast_step(step: Questions::NullStep.new, previous_step: Questions::NullStep.new)
    messages = Array(previous_step.follow_up_message) + Array(step.errors) + step.messages

    self.class.broadcast_to(
      current_donor,
      messages: messages,
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
