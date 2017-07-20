# Based on production defaults
require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.action_mailer.default_url_options = { host: "#{ENV['HEROKU_APP_NAME']}.herokuapp.com" }
  config.action_mailer.asset_host = "http://#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
  config.action_controller.asset_host = "#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
  config.action_cable.url = "wss://#{ENV['HEROKU_APP_NAME']}.herokuapp.com/cable"
end
