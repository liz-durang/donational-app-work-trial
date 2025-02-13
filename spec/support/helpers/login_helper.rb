module Helpers
  module LoginHelper
    def login_as(donor)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
      allow_any_instance_of(ApplicationController).to receive(:current_currency).and_return(Money::Currency.new('USD'))
    end
  end
end
