source 'https://rubygems.org'

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Base stack
gem 'pg'
gem 'puma', '~> 3.0'
gem 'rails', '~> 5.1.0'
gem 'redis', '~> 3.3.3'

# Models
gem 'enumerize', '~> 2.1'

# Views
gem 'commonmarker', '~> 0.17.9'

# Authentication
gem 'omniauth'
gem 'omniauth-auth0'

# Assets
gem 'jquery-rails'
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'slim-rails'

source 'https://rails-assets.org' do
  gem 'rails-assets-bulma'
end

# Monitoring
gem 'sentry-raven'
gem 'analytics-ruby'
gem 'appsignal'

# Commands
gem 'mutations'

# API
gem 'jbuilder', '~> 2.5'

# Payments
gem 'rest-client'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'pry'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
end

group :development do
  gem 'annotate', require: false
  gem 'listen', '~> 3.0.5'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'database_cleaner'
  gem 'climate_control'
  gem 'capybara'
  gem 'capybara-selenium'
end
