require 'sidekiq-scheduler'

class ApplicationJob
  include Sidekiq::Worker
end
