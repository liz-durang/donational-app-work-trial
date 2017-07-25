class SignupChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_donor

    steps = begin
      Onboarding::AreYouReady.new(current_donor) <<
      Onboarding::DidYouDonateLastYear.new(current_donor) <<
      Onboarding::HowMuchShouldAnIndividualGive.new(current_donor) <<
      Onboarding::DoYouKnowTheAverageContribution.new(current_donor) <<
      Onboarding::HowMuchWillYouContribute.new(current_donor) <<
      Onboarding::WhatIsYourPreTaxIncome.new(current_donor) <<
      Onboarding::LocalOrGlobalImpact.new(current_donor) <<
      Onboarding::ImmediateOrLongTerm.new(current_donor) <<
      Onboarding::ComingSoon.new(current_donor) <<
      Onboarding::LastStep.new(current_donor)
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
    Rails.logger.info(data['response'])

    if @current_step.process!(data['response'])
      next_step = @current_step.next_node

      if next_step
        broadcast_step(step: next_step, previous_step: @current_step)
        @current_step = next_step
      else
        broadcast_completion
      end
    else
      broadcast_step(step: @current_step, previous_step: ErrorStep.new)
    end
  end

  private

  def broadcast_completion
    self.class.broadcast_to(
      current_donor,
      redirect_to: Rails.application.routes.url_helpers.subscription_path
    )
  end

  def broadcast_step(step: NullStep.new, previous_step: NullStep.new)
    messages = Array(previous_step.follow_up_message) + Array(step.errors) + step.messages

    self.class.broadcast_to(
      current_donor,
      messages: messages,
      responses: render_responses(step)
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
