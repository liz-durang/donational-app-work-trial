# frozen_string_literal: true

ENV['HOST'] = "#{ENV['HEROKU_APP_NAME']}.herokuapp.com"

# Based on production defaults
require Rails.root.join('config/environments/production')
