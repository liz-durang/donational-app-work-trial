class SignupChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_donor

    @wizard = Wizard.new([
      Questions::AreYouReady.new,
      Questions::HowMuchShouldAnIndividualGive.new,
      Questions::DoYouKnowTheAverageContribution.new,
      Questions::HowMuchWillYouContribute.new,
      Questions::WhatIsYourPreTaxIncome.new
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
      broadcast_step(step: @wizard.next_step!, previous_response: step.response)
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
