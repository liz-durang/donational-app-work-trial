require 'rails_helper'

RSpec.describe CauseAreaRelevance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:donor) }
  end
end
