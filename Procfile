web: bundle exec puma -C config/puma.rb
workers: bundle exec sidekiq -q default -q mailers -q searchkick
release: rake db:migrate
