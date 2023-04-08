# frozen_string_literal: true

require 'webdrivers'

# Set path to chrome binary when running on Heroku CI
# https://github.com/heroku/heroku-buildpack-google-chrome#selenium
Selenium::WebDriver::Chrome.path = ENV.fetch('GOOGLE_CHROME_SHIM', nil) if ENV['GOOGLE_CHROME_SHIM'].present?

# Silence puma in logs
Capybara.server = :puma, { Silent: true }

Capybara.register_driver :chrome_headful do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument('--window-size=1920,1080')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument('--headless')
    opts.add_argument('--window-size=1920,1080')
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

driver = ENV.fetch('DRIVER', '') == 'HEADFUL' ? :chrome_headful : :chrome_headless

Capybara.default_driver = driver
Capybara.javascript_driver = driver
Capybara.automatic_label_click = true
