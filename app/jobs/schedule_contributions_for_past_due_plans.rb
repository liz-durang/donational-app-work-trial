class ScheduleContributionsForPastDuePlans < ApplicationJob
  include ScheduledToRepeat

  def perform
    Contributions::ScheduleContributionsForPastDuePlans.run
  end
end
