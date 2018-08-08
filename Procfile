web: bundle exec puma -C config/puma.rb
workers: bundle exec sidekiq -q default -q mailers
release: rake db:migrate
