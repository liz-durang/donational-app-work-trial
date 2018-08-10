class ProcessScheduledContributions < ApplicationJob
  include ScheduledToRepeat

  def perform
    unprocessed_contributions.each do |contribution|
      Contributions::ProcessContribution.run!(contribution: contribution)
    end
    puts "Processed #{unprocessed_contributions.count} contributions"
  end

  private

  def unprocessed_contributions
    Contributions::GetUnprocessedContributions.call(scheduled_before: Time.zone.now)
  end
end
