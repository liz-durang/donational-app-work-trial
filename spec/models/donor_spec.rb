# frozen_string_literal: true

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

RSpec.describe Donor do
  describe 'associations' do
    it { is_expected.to have_many(:selected_portfolios) }
    it { is_expected.to have_many(:portfolios).through(:selected_portfolios) }
    it { is_expected.to have_many(:payment_methods) }
    it { is_expected.to have_many(:partner_affiliations) }
    it { is_expected.to have_many(:subscriptions) }
    it { is_expected.to have_and_belong_to_many(:partners) }
  end

  describe 'validations' do
    context 'when uk_gift_aid_accepted is true' do
      subject { build(:donor, :with_uk_gift_aid_accepted) }

      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_presence_of(:first_name) }
      it { is_expected.to validate_length_of(:first_name).is_at_most(35) }
      it { is_expected.to validate_presence_of(:last_name) }
      it { is_expected.to validate_length_of(:last_name).is_at_most(35) }
      it { is_expected.to validate_presence_of(:house_name_or_number) }
      it { is_expected.to validate_presence_of(:postcode) }

      it 'validates postcode format' do
        subject.postcode = 'invalid_postcode'
        expect(subject).not_to be_valid
        expect(subject.errors[:postcode]).to include('must include a space e.g. AA1 3DD')
      end
    end

    context 'when uk_gift_aid_accepted is false' do
      subject { build(:donor) }

      it 'does not validate presence of title' do
        subject.title = nil
        expect(subject).to be_valid
      end

      it 'does not validate presence of first_name' do
        subject.first_name = nil
        expect(subject).to be_valid
      end

      it 'does not validate presence of last_name' do
        subject.last_name = nil
        expect(subject).to be_valid
      end

      it 'does not validate presence of house_name_or_number' do
        subject.house_name_or_number = nil
        expect(subject).to be_valid
      end

      it 'does not validate presence of postcode' do
        subject.postcode = nil
        expect(subject).to be_valid
      end
    end

    it 'validates presence of required fields', :aggregate_failures do
      valid_donor = build(:donor, first_name: nil, last_name: nil,
                                  title: nil, house_name_or_number: nil)
      valid_uk_donor = build(:donor, :with_uk_gift_aid_accepted)
      invalid_uk_donor = build(
        :donor, 
        :with_uk_gift_aid_accepted, 
        first_name: nil, 
        last_name: nil,
        title: nil, 
        house_name_or_number: nil
      )
      expect(valid_donor).to be_valid
      expect(valid_uk_donor).to be_valid
      expect(invalid_uk_donor).not_to be_valid

      expect(invalid_uk_donor.errors.messages[:first_name]).to include("can't be blank")
      expect(invalid_uk_donor.errors.messages[:last_name]).to include("can't be blank")
      expect(invalid_uk_donor.errors.messages[:title]).to include("can't be blank")
      expect(invalid_uk_donor.errors.messages[:house_name_or_number]).to include("can't be blank")
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
          expect(invalid_uk_donor.errors.messages[:postcode]).to include('must include a space e.g. AA1 3DD')
        end
      end
    end
  end

  describe 'enums' do
    describe '.portfolio_diversity' do
      it do
        expect(subject).to define_enum_for(:portfolio_diversity)
          .with_values(focused: 1, mixed: 2, broad: 3)
          .backed_by_column_of_type(:integer)
      end
    end

    describe '.contribution_frequency' do
      it 'defines the enumerized attribute' do
        expect(described_class.enumerized_attributes[:contribution_frequency].values)
          .to match_array(%w[never once monthly quarterly annually])
      end

      it 'validates inclusion in the enumerized values' do
        donor = described_class.new(contribution_frequency: 'invalid_value')
        expect(donor).not_to be_valid
        expect(donor.errors[:contribution_frequency])
          .to include('is not included in the list')
      end

      context 'with valid values' do
        %w[never once monthly quarterly annually].each do |frequency|
          it "allows #{frequency} as a valid contribution_frequency" do
            donor = described_class.new(contribution_frequency: frequency)
            expect(donor).to be_valid
          end
        end
      end
    end
  end

  describe 'methods' do
    describe '#generate_username' do
      let(:donor) { build(:donor, first_name: 'John', last_name: 'Doe', username: nil) }

      context 'when username is already present' do
        it 'does not generate a new username' do
          donor.username = 'existing_username'
          donor.generate_username
          expect(donor.username).to eq('existing_username')
        end
      end

      context 'when username is not present' do
        it 'generates a username based on the name' do
          donor.generate_username
          expect(donor.username).to eq('john-doe')
        end

        it 'handles conflicts by appending a suffix' do
          create(:donor, username: 'john-doe')
          donor.generate_username
          expect(donor.username).to match(/^john-doe-\w{7}$/)
        end

        it 'handles blank names by generating a random suffix' do
          donor.first_name = nil
          donor.last_name = nil
          donor.generate_username
          expect(donor.username).to match(/^\w{7}$/)
        end

        it 'stops recursion when a unique username is found' do
          allow(SecureRandom).to receive(:uuid).and_return('c1', 'c2', 'u1')
          create(:donor, username: 'john-doe')
          create(:donor, username: 'john-doe-c1')
          create(:donor, username: 'john-doe-c2')

          donor.generate_username
          expect(donor.username).to eq('john-doe-u1')
        end
      end
    end

    describe '#active?' do
      let(:donor) { build(:donor) }

      context 'when deactivated_at is nil' do
        it 'returns true' do
          donor.deactivated_at = nil
          expect(donor.active?).to be true
        end
      end

      context 'when deactivated_at is present' do
        it 'returns false' do
          donor.deactivated_at = Time.current
          expect(donor.active?).to be false
        end
      end
    end

    describe '#name' do
      let(:donor) { build(:donor, entity_name: nil, first_name: nil, last_name: nil) }

      context 'when entity_name is present' do
        it 'returns the entity_name' do
          donor.entity_name = 'Charitable Foundation'
          donor.first_name = 'John'
          donor.last_name = 'Doe'
          expect(donor.name).to eq('Charitable Foundation')
        end
      end

      context 'when entity_name is nil' do
        it 'returns the concatenated first and last name' do
          donor.first_name = 'John'
          donor.last_name = 'Doe'
          expect(donor.name).to eq('John Doe')
        end

        it 'returns only the first name if last name is nil' do
          donor.first_name = 'John'
          donor.last_name = nil
          expect(donor.name).to eq('John')
        end

        it 'returns only the last name if first name is nil' do
          donor.first_name = nil
          donor.last_name = 'Doe'
          expect(donor.name).to eq('Doe')
        end

        it 'returns an empty string if both first_name and last_name are nil' do
          expect(donor.name).to eq('')
        end
      end
    end

    describe '#last_name_initial' do
      context 'with last name present' do
        let(:donor) { build(:donor, last_name: 'Last Name') }

        it 'returns last name initial' do
          expect(donor.last_name_initial).to eq('L.')
        end
      end

      context 'with last name nil' do
        let(:donor) { build(:donor, last_name: nil) }

        it 'returns nil' do
          expect(donor.last_name_initial).to be_nil
        end
      end
    end

    describe '#anonymized_name' do
      let(:donor) { build(:donor, entity_name: nil, first_name: nil, last_name: nil) }

      context 'when entity_name is present' do
        it 'returns the entity_name' do
          donor.entity_name = 'Charitable Foundation'
          donor.first_name = 'John'
          donor.last_name = 'Doe'
          expect(donor.anonymized_name).to eq('Charitable Foundation')
        end
      end

      context 'when entity_name is nil' do
        it 'returns the first name with the initial of the last name' do
          donor.first_name = 'John'
          donor.last_name = 'Doe'
          expect(donor.anonymized_name).to eq('John D.')
        end

        it 'returns only the first name if last name is nil' do
          donor.first_name = 'John'
          donor.last_name = nil
          expect(donor.anonymized_name).to eq('John')
        end

        it 'returns only the last name initial if first name is nil' do
          donor.first_name = nil
          donor.last_name = 'Doe'
          expect(donor.anonymized_name).to eq('D.')
        end

        it 'returns an empty string if both first_name and last_name are nil' do
          expect(donor.anonymized_name).to eq('')
        end
      end
    end

    describe '#short_name' do
      context 'when donor is person' do
        let(:donor) { build(:donor, entity_name: nil, first_name: 'John') }

        it 'returns the first name' do
          expect(donor.short_name).to eq('John')
        end
      end

      context 'when donor is entity' do
        let(:donor) { build(:donor, entity_name: 'Entity', first_name: 'John') }

        it 'returns entity name' do
          expect(donor.short_name).to eq('Entity')
        end
      end
    end

    describe '#entity?' do
      context 'when entity_name present' do
        let(:donor) { build(:donor, entity_name: 'Entity') }

        it 'returns true' do
          expect(donor.entity?).to be(true)
        end
      end
    end

    describe '#person?' do
      context 'when entity_name is nil' do
        let(:donor) { build(:donor, entity_name: nil) }

        it 'returns true' do
          expect(donor.person?).to be(true)
        end
      end
    end

    describe '#account_holder?' do
      context 'when email is present' do
        let(:donor) { build(:donor, email: 'user@email.com') }

        it 'returns true' do
          expect(donor.account_holder?).to be(true)
        end
      end
    end

    describe '#contribution_frequency' do
      context 'when contribution_frequency is present' do
        let(:donor) { build(:donor, contribution_frequency: 'once') }

        it 'returns contribution frequency' do
          expect(donor.contribution_frequency).to eq('once')
        end
      end

      context 'when contribution_frequency is nil' do
        let(:donor) { build(:donor, contribution_frequency: nil) }

        it 'returns monthly' do
          expect(donor.contribution_frequency).to eq('monthly')
        end
      end
    end

    describe '#time_zone' do
      let(:donor) { build(:donor) }

      it 'describes eastern time' do
        expect(donor.time_zone).to eq('Eastern Time (US & Canada)')
      end
    end
  end
end
