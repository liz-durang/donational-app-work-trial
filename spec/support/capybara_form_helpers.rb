module CapybaraFormHelpers
  def click_on_label(text)
    find('label', text: text, match: :prefer_exact).click
  end
end

RSpec.configure do |config|
  config.include CapybaraFormHelpers, type: :feature
end
