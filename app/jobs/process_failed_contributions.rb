class ProcessFailedContributions < ApplicationJob
  include ScheduledToRepeat

  def perform
    unprocessed_failed_contributions.each do |contribution|
      Contributions::ProcessContribution.run!(contribution: contribution)
    end
    puts "Processed #{unprocessed_contributions.count} contributions"
  end

  private

  def unprocessed_failed_contributions
    # Retry payment 1 week after it failed
    failed_after = Date.today.beginning_of_day - 7.days
    failed_before = Date.today.end_of_day - 7.days

    Contributions::GetUnprocessedFailedContributions.call(failed_after: failed_after, failed_before: failed_before)
  end
end
