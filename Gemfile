# frozen_string_literal: true

source 'https://rubygems.org'

# Set Ruby version
ruby File.read('.ruby-version').strip

# Base stack
gem 'bootsnap', require: false
gem 'pg'
gem 'puma'
gem 'rails', '~> 7.0.0'
gem 'redis'

# Uploads
gem 'aws-sdk-s3', require: false
gem 'image_processing'
gem 'mini_magick'

# Models
gem 'enumerize', '~> 2.1'

# Views
gem 'commonmarker'
gem 'kaminari'
gem 'premailer-rails'

# Jobs
gem 'sidekiq'
gem 'sidekiq-scheduler', github: 'sidekiq-scheduler/sidekiq-scheduler'

# Authentication
gem 'omniauth'
gem 'omniauth-auth0'
gem 'omniauth-rails_csrf_protection'

# Assets
gem 'jquery-rails'
gem 'sassc-rails'
gem 'slim-rails'
gem 'sprockets-rails'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker'

source 'https://rails-assets.org' do
  gem 'rails-assets-bulma'
end

# Monitoring
gem 'analytics-ruby'
gem 'barnes'
gem 'gem-licenses'
gem 'lograge'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sentry-sidekiq'

# Commands
gem 'mutations'

# Payments
gem 'money-rails'
gem 'plaid', '~> 12.0'
gem 'stripe'

# Search
gem 'elasticsearch'
gem 'searchkick'

# External Integrations
gem 'faraday'

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'pry'
end

group :development do
  gem 'annotate', require: false
  gem 'letter_opener'
  gem 'listen', '~> 3.0.5'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara'
  gem 'capybara-webmock'
  gem 'climate_control'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 5.0.0'
  gem 'selenium-webdriver'
  gem 'stripe-ruby-mock', github: 'donational-org/stripe-ruby-mock', branch: 'support-cloned-payment-methods',
                          require: 'stripe_mock'
  gem 'webdrivers'
  gem 'webmock'
end
