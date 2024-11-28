require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:grants).with_foreign_key('organization_ein') }
    it { is_expected.to have_many(:donations).with_foreign_key('organization_ein') }
    it { should belong_to(:suggested_by_donor).class_name('Donor').with_foreign_key('suggested_by_donor_id').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:ein) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'enums' do
    describe "#cause_area" do
      subject { build(:organization) }

      it 'should allow valid cause_area values' do
        valid_values = described_class::CAUSE_AREAS
        valid_values.each do |value|
          subject.cause_area = value
          expect(subject).to be_valid
        end
      end

      it 'should reject invalid cause_area values' do
        invalid_values = ['invalid_area', 'another_invalid_area']
        invalid_values.each do |invalid_value|
          subject.cause_area = invalid_value
          expect(subject).not_to be_valid
        end
      end

      it 'should assign a default cause_area value if set' do
        subject.save
        expect(subject.cause_area).to eq('user_added_organization')
      end

      it 'responds to predicate methods for cause_area' do
        subject.cause_area = 'global_health'
        subject.save
        expect(subject.cause_area.global_health?).to be true
        expect(subject.cause_area.poverty_and_income_inequality?).to be false
      end
    end
  end

  describe 'class methods' do
    describe '.recommendable_cause_areas' do
      subject { described_class.recommendable_cause_areas }

      it 'removes user_added_organization' do
        expect(subject).to eq(described_class::CAUSE_AREAS - ['user_added_organization'])
      end
    end
  end

  describe 'instance methods' do
    describe '#active?' do
      context 'when deactivated_at nil' do
        let(:organization) { build(:organization, deactivated_at: nil) }

        it 'returns true' do
          expect(organization.active?).to eq(true)
        end
      end
    end

    describe '#suggested_by_donor?' do
      context 'when suggested_by_donor present' do
        let(:organization) { build(:organization, suggested_by_donor: create(:donor)) }

        it 'returns true' do
          expect(organization.suggested_by_donor?).to eq(true)
        end
      end
    end

    describe '#grants_routed_via_another_organization?' do
      context 'when ein with routing separator' do
        let(:organization) { build(:organization, ein: '123|abc') }

        it 'returns true' do
          expect(organization.grants_routed_via_another_organization?).to eq(true)
        end
      end
    end

    describe '#displayable_ein?' do
      context 'when ein with routing separator' do
        let(:organization) { build(:organization, ein: '123|abc') }

        it 'returns true' do
          expect(organization.grants_routed_via_another_organization?).to eq(true)
        end
      end
    end

    describe '#cause_area' do
      context 'when cause_area is specified' do
        let(:organization) { build(:organization, cause_area: 'global_health') }

        it 'returns the cause area' do
          expect(organization.cause_area).to eq('global_health')
        end
      end

      context 'when cause_area is nil' do
        let(:organization) { build(:organization) }

        it 'returns the default' do
          expect(organization.cause_area).to eq('user_added_organization')
        end
      end
    end
  end
end
