class OnboardingChannel < ApplicationCable::Channel
  def subscribed
    stream_for "#{current_donor.id}-#{params['room']}"

    @wizard = Wizard.new(
      steps: begin
        Onboarding::AreYouReady.new(current_donor) <<
        Onboarding::WhatIsYourFirstName.new(current_donor) <<
        Onboarding::PrimaryReasons.new(current_donor) <<
        Onboarding::HowDoYouDecideWhichOrganizationsToSupport.new(current_donor) <<
        Onboarding::DidYouDonateLastYear.new(current_donor) <<
        # Onboarding::DoYouKnowTheAverageContribution.new(current_donor) <<
        Onboarding::ImportanceOfGlobalHealth.new(current_donor) <<
        Onboarding::ImportanceOfPovertyAndIncomeInequality.new(current_donor) <<
        Onboarding::ImportanceOfClimateAndEnvironment.new(current_donor) <<
        Onboarding::ImportanceOfAnimalWelfare.new(current_donor) <<
        Onboarding::ImportanceOfHungerNutritionAndSafeWater.new(current_donor) <<
        Onboarding::ImportanceOfImmigrationAndRefugees.new(current_donor) <<
        # Onboarding::ImportanceOfEconomicDevelopment.new(current_donor) <<
        Onboarding::ImportanceOfWomenAndGirlsIssues.new(current_donor) <<
        Onboarding::HowOftenWillYouContribute.new(current_donor) <<
        # Onboarding::SupportExtremePovertyAlleviation.new(current_donor) <<
        # Onboarding::SupportLifeSavingHealthInterventions.new(current_donor) <<
        # Onboarding::SupportAnimalSufferingPrevention.new(current_donor) <<
        # Onboarding::ImmediateOrLongTerm.new(current_donor) <<
        # Onboarding::LocalOrGlobalImpact.new(current_donor) <<
        Onboarding::WhatIsYourEmail.new(current_donor)
        # Onboarding::WhatIsYourPreTaxIncome.new(current_donor) <<
        # Onboarding::HowMuchShouldAnIndividualGive.new(current_donor) <<
        # Onboarding::HowMuchWillYouContribute.new(current_donor) <<
      end
    )
  end

  def unsubscribed
    @wizard = nil
  end

  def start
    @wizard.restart!
    broadcast_step(step: @wizard.current_step)
  end

  def respond(data)
    Rails.logger.info("Processing #{@wizard.current_step.class} with #{data}")

    params = Rack::Utils.parse_nested_query(data['payload'])

    @wizard.process_step!(params['response'])

    if @wizard.finished?
      broadcast_completion
    else
      broadcast_step(step: @wizard.current_step, previous_step: @wizard.previous_step)
    end
  end

  private

  def broadcast_completion
    self.class.broadcast_to(
      "#{current_donor.id}-#{params['room']}",
      redirect_to: Rails.application.routes.url_helpers.new_portfolio_path
    )
    Analytics::TrackEvent.run(
      user_id: current_donor.id,
      event: 'Onboarding finished'
    )
  end

  def broadcast_step(step: NullStep.new, previous_step: NullStep.new)
    self.class.broadcast_to(
      "#{current_donor.id}-#{params['room']}",
      messages: previous_step.follow_up_messages + step.error_messages + step.messages,
      heading: step.heading,
      responses: render_responses(step)
    )
  end

  def render_responses(step)
    return '' unless step

    ApplicationController.renderer.render(
      partial: "conversations/#{step.display_as}",
      locals: { step: step }
    )
  end
end
