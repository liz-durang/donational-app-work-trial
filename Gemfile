# frozen_string_literal: true

source 'https://rubygems.org'

# Set Ruby version
ruby File.read('.ruby-version').strip

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Base stack
gem 'pg'
gem 'puma', '~> 3.12'
gem 'rails', '~> 5.2.0'
gem 'redis', '~> 3.3.3'
gem 'bootsnap', require: false

# Uploads
gem 'active_storage-postgresql', github: 'lsylvester/active_storage-postgresql'
gem 'mini_magick'

# Models
gem 'enumerize', '~> 2.1'

# Views
gem 'commonmarker', '~> 0.17.9'
gem 'premailer-rails'

# Jobs
gem 'sidekiq'
gem 'sidekiq-scheduler'

# Authentication
gem 'omniauth'
gem 'omniauth-auth0'

# Assets
gem 'jquery-rails'
gem 'sassc-rails'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'slim-rails'
gem 'webpacker'

source 'https://rails-assets.org' do
  gem 'rails-assets-bulma'
end

# Monitoring
gem 'sentry-raven'
gem 'analytics-ruby'
gem 'appsignal'
gem 'lograge'

# Commands
gem 'mutations'

# Multi-currency operations
gem 'money-rails'

# API
gem 'rack-cors'
gem 'jbuilder', '~> 2.7.0'
gem 'apitome'
gem 'rspec_api_documentation'

# Payments
gem 'stripe'

# Search
gem 'searchkick'
gem 'elasticsearch', '~> 6.0'

# External Integrations
gem 'faraday'

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
  gem 'pry'
  gem 'dotenv-rails'
end

group :development do
  gem 'annotate', require: false
  gem 'listen', '~> 3.0.5'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  gem 'letter_opener'
end

group :test do
  gem 'database_cleaner'
  gem 'climate_control'
  gem 'capybara'
  gem 'capybara-selenium'
  gem 'selenium-webdriver', '~> 3.12.0'
  gem 'stripe-ruby-mock', '~> 2.5.4', require: 'stripe_mock'
  gem 'capybara-webmock'
  gem 'puffing-billy'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
end
