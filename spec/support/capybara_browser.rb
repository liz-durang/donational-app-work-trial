# frozen_string_literal: true

# Silence puma in logs
Capybara.server = :puma, { Silent: true }

# Ensure Selenium can find the chrome binary installed by heroku-buildpack-google-chrome when running on Heroku CI
# https://github.com/heroku/heroku-buildpack-google-chrome/pull/146
chrome_shim = ENV.fetch('GOOGLE_CHROME_SHIM', nil)

Capybara.register_driver :chrome_headful do |app|
  options = if chrome_shim.present?
              ::Selenium::WebDriver::Chrome::Options.new(binary: chrome_shim)
            else
              ::Selenium::WebDriver::Chrome::Options.new
            end
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.register_driver :chrome_headless do |app|
  options = if ENV['GOOGLE_CHROME_SHIM'].present?
              ::Selenium::WebDriver::Chrome::Options.new(binary: chrome_shim)
            else
              ::Selenium::WebDriver::Chrome::Options.new
            end
  options.add_argument('--headless')
  options.add_argument('--window-size=1920,1080')
  # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
  options.add_argument('--disable-site-isolation-trials')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

driver = ENV.fetch('DRIVER', '') == 'HEADFUL' ? :chrome_headful : :chrome_headless

Capybara.default_driver = driver
Capybara.javascript_driver = driver
Capybara.automatic_label_click = true
