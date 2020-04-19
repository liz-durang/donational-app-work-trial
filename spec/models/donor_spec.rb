# == Schema Information
#
# Table name: donors
#
#  id                                          :uuid             not null, primary key
#  first_name                                  :string
#  last_name                                   :string
#  email                                       :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  donation_rate                               :decimal(, )
#  annual_income_cents                         :integer
#  donated_prior_year                          :boolean
#  satisfaction_with_prior_donation            :string
#  donation_rate_expected_from_individuals     :decimal(, )
#  surprised_by_average_american_donation_rate :string
#  include_immediate_impact_organizations      :boolean          default(TRUE)
#  include_long_term_impact_organizations      :boolean          default(TRUE)
#  include_local_organizations                 :boolean          default(TRUE)
#  include_global_organizations                :boolean          default(TRUE)
#  username                                    :string
#  giving_challenges                           :string           default([]), is an Array
#  reasons_why_i_choose_an_organization        :string           default([]), is an Array
#  contribution_frequency                      :string
#  portfolio_diversity                         :integer
#  entity_name                                 :string
#  title                                       :string
#  house_name_or_number                        :string
#  postcode                                    :string
#  uk_gift_aid_accepted                        :boolean          default(FALSE), not null
#

require 'rails_helper'

RSpec.describe Donor, type: :model do
  describe 'validations' do
    it 'validates presence of required fields', :aggregate_failures do
      valid_donor = build(:donor, first_name: nil, last_name: nil,
                          title: nil, house_name_or_number: nil)
      valid_uk_donor = build(:donor, :with_uk_gift_aid_accepted)
      invalid_uk_donor = build(:donor, :with_uk_gift_aid_accepted, first_name: nil, last_name: nil,
                               title: nil, house_name_or_number: nil)      
      expect(valid_donor).to be_valid
      expect(valid_uk_donor).to be_valid
      expect(invalid_uk_donor).not_to be_valid

      expect(invalid_uk_donor.errors.messages).to include(first_name: ["can't be blank"])
      expect(invalid_uk_donor.errors.messages).to include(last_name: ["can't be blank"])
      expect(invalid_uk_donor.errors.messages).to include(title: ["can't be blank"])
      expect(invalid_uk_donor.errors.messages).to include(house_name_or_number: ["can't be blank"])
    end

    context 'when correct postocde was provided' do
      let(:valid_postcodes) { ['EC1A 1BB', 'W1A 0AX', 'M1 1AE', 'B33 8TH', 'CR2 6XH', 'DN55 1PT'] }
      let(:valid_uk_donors) do 
        valid_postcodes.map { |vp| build(:donor, :with_uk_gift_aid_accepted, postcode: vp) }
      end

      it { expect(valid_uk_donors).to all(be_valid) }
    end

    context 'when incorrect postocde was provided' do
      let(:invalid_postcodes) { ['EC1 A1BB', 'W1A 0AXA', 'MJ 1AE', 'CRZ 6XH', 'DN55 VPT', 'ab12aa'] }
      let(:invalid_uk_donors) do 
        invalid_postcodes.map { |ip| build(:donor, :with_uk_gift_aid_accepted, postcode: ip) }
      end

      it 'all should not be valid', :aggregate_failures do
        invalid_uk_donors.map do |invalid_uk_donor|
          expect(invalid_uk_donor).not_to(be_valid)
          expect(invalid_uk_donor.errors.messages).to include(postcode: ["must include a space e.g. AA1 3DD"])
        end
      end
    end
  end
end
