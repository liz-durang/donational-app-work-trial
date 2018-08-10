module ScheduledToRepeat
  extend ActiveSupport::Concern

  included do
    # Prevent retries, as a new instance of this job will run on schedule
    sidekiq_options retry: false
  end
end
