require 'rails_helper'

RSpec.describe CampaignContribution, type: :model do
  describe "attributes" do
    it { is_expected.to respond_to(:first_name) }
    it { is_expected.to respond_to(:last_name) }
    it { is_expected.to respond_to(:email) }
    it { is_expected.to respond_to(:amount_dollars) }
    it { is_expected.to respond_to(:frequency) }
    it { is_expected.to respond_to(:start_at) }
    it { is_expected.to respond_to(:managed_portfolio_id) }
  end
end
