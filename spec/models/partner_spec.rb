# == Schema Information
#
# Table name: partners
#
#  id                           :uuid             not null, primary key
#  name                         :string
#  website_url                  :string
#  description                  :text
#  platform_fee_percentage      :decimal(, )      default(0.0)
#  primary_branding_color       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donor_questions_schema       :jsonb
#  payment_processor_account_id :string
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
end
