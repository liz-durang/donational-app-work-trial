class ProcessDonationPlans < ApplicationJob
  include ScheduledToRepeat

  def perform
    Contributions::ProcessDonationPlans.run
  end
end
