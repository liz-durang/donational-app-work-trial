# == Schema Information
#
# Table name: campaigns
#
#  id                            :uuid             not null, primary key
#  partner_id                    :uuid
#  title                         :string
#  description                   :text
#  slug                          :string
#  target_amount_cents           :integer
#  default_contribution_amounts  :string           is an Array
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  contribution_amount_help_text :string
#  allow_one_time_contributions  :boolean          default(TRUE), not null
#  minimum_contribution_amount   :integer          default(10)
#

require 'rails_helper'

RSpec.describe Campaign, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:partner) }
    it { is_expected.to have_one_attached(:banner_image) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "methods" do
    describe "#allowable_donation_frequencies" do
      context "when allow_one_time_contributions is true" do
        it "returns the options for 'once' and 'monthly'" do
          campaign = Campaign.new(allow_one_time_contributions: true)
          expect(campaign.allowable_donation_frequencies).to eq([["Monthly", "monthly"], ["One-time", "once"]])
        end
      end

      context "when allow_one_time_contributions is false" do
        it "returns the option for 'monthly'" do
          campaign = Campaign.new(allow_one_time_contributions: false)
          expect(campaign.allowable_donation_frequencies).to eq([["Monthly", "monthly"]])
        end
      end
    end
  end
end
