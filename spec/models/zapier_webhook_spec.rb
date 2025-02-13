require 'rails_helper'

RSpec.describe ZapierWebhook, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:partner) }
  end
end
