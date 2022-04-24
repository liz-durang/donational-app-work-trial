# frozen_string_literal: true

require 'selenium/webdriver'

Capybara.register_driver :headless_chrome do |app|
  capabilities = { chromeOptions: { args: %w[headless disable-gpu window-size=1440,900] } }

  # Set path to chrome binary when running on Heroku CI
  # https://github.com/heroku/heroku-buildpack-google-chrome#selenium
  chrome_binary_path = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
  capabilities[:chromeOptions][:binary] = chrome_binary_path if chrome_binary_path
  capabilities[:chromeOptions][:w3c] = false

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(capabilities)
  )
end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.javascript_driver = ENV['CI'] ? :headless_chrome : :chrome
