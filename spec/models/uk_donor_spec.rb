require 'rails_helper'

RSpec.describe UkDonor, type: :model do
  describe 'validations' do
    it 'validates presence of required fields', :aggregate_failures do
      invalid_uk_donor = build(:uk_donor, first_name: nil, last_name: nil, title: nil,
                                          house_name_or_number: nil)
      valid_uk_donor = create(:uk_donor)

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
        valid_postcodes.map { |vp| build(:uk_donor, postcode: vp) }
      end

      it { expect(valid_uk_donors).to all(be_valid) }
    end

    context 'when incorrect postocde was provided' do
      let(:invalid_postcodes) { ['EC1 A1BB', 'W1A 0AXA', 'MJ 1AE', 'CRZ 6XH', 'DN55 VPT'] }
      let(:invalid_uk_donors) do 
        invalid_postcodes.map { |ip| build(:uk_donor, postcode: ip) }
      end

      it 'all should not be valid', :aggregate_failures do
        invalid_uk_donors.map do |invalid_uk_donor|
          expect(invalid_uk_donor).not_to(be_valid)
          expect(invalid_uk_donor.errors.messages).to include(postcode: ["is not a valid postcode"])
        end
      end
    end
  end
end
