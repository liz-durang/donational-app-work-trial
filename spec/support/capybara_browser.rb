require "selenium/webdriver"

Capybara.register_driver :chrome do |app|
  capabilities = { chromeOptions: { args: %w(headless disable-gpu) } }

  # Set path to chrome binary when running on Heroku CI
  # https://github.com/heroku/heroku-buildpack-google-chrome#selenium
  chrome_binary_path = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
  capabilities[:chromeOptions][:binary] = chrome_binary_path if chrome_binary_path

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(capabilities)
  )
end

Capybara.javascript_driver = :chrome
