require 'rails_helper'

RSpec.describe ProfileContribution, type: :model do
  describe 'attributes' do
    it { should respond_to(:first_name) }
    it { should respond_to(:last_name) }
    it { should respond_to(:email) }
    it { should respond_to(:amount_dollars) }
    it { should respond_to(:frequency) }
    it { should respond_to(:start_at) }
    it { should respond_to(:portfolio_id) }
  end
end
