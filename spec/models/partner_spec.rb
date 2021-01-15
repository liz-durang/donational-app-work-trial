# == Schema Information
#
# Table name: partners
#
#  id                                :uuid             not null, primary key
#  name                              :string
#  website_url                       :string
#  description                       :text
#  platform_fee_percentage           :decimal(, )      default(0.0)
#  primary_branding_color            :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  donor_questions_schema            :jsonb
#  payment_processor_account_id      :string
#  api_key                           :string
#  operating_costs_text              :string
#  operating_costs_organization_ein  :string
#  currency                          :string           default("usd"), not null
#  email_receipt_preamble            :text
#  after_donation_thank_you_page_url :string
#  receipt_first_paragraph           :text
#  receipt_second_paragraph          :text
#  receipt_tax_info                  :text
#  receipt_charity_name              :string
#  donor_advised_fund_fee_percentage :decimal(, )      default(0.01)
#

require 'rails_helper'

RSpec.describe Partner, type: :model do
  describe 'validations' do
    it 'validates correctness of the currency field', :aggregate_failures do
      valid_partner = build(:partner, currency: 'gbp')
      invalid_partner = build(:partner, currency: 'xyz')

      expect(valid_partner).to be_valid
      expect(invalid_partner).not_to be_valid
      expect(invalid_partner.errors.messages).to include(
        currency: include('xyz is not a valid currency iso code')
      )
    end
  end

  describe 'Plaid compatibility' do
    around do |example|
      ClimateControl.modify(PLAID_ENABLED: 'true') do
        example.run
      end
    end
    
    it 'supports Plaid if the currency is USD' do
      partner = build(:partner, currency: 'usd')
      expect(partner.supports_plaid?).to be true
    end

    it 'does not support Plaid if the currency is not USD' do
      partner1 = build(:partner, currency: 'gbp')
      partner2 = build(:partner, currency: 'eur')
      expect(partner1.supports_plaid?).to be false
      expect(partner2.supports_plaid?).to be false
    end
  end
end
