require 'rails_helper'

RSpec.describe Portfolios::GetRecommendedAllocations, type: :query do
  let(:service) { described_class.new }
  let(:donor) { create(:donor, portfolio_diversity: portfolio_diversity) }
  let(:organizations) { create_list(:organization, 10) }
  let(:organization_double) { instance_double('Organization', ein: '12345') }
  let(:organization_relation) { instance_double('ActiveRecord::Relation') }

  before do
    allow(Organizations::GetOrganizationsThatMatchPriorities).to receive(:call).with(donor: donor).and_return(organization_relation)
    allow(organization_relation).to receive(:distinct).and_return(organizations)
    allow(organization_relation).to receive(:count).with(:cause_area).and_return(organizations_count)
    allow(organization_relation).to receive(:group_by).and_return(grouped_organizations)
  end

  describe '#call' do
    subject { service.call(donor: donor) }

    context 'when portfolio diversity is focused' do
      let(:portfolio_diversity) { 'focused' }
      let(:organizations_count) { 2 }
      let(:grouped_organizations) { { 'cause_area_1' => [organization_double, organization_double], 'cause_area_2' => [organization_double, organization_double] } }

      it 'returns allocations with 2 organizations per cause area' do
        expect(subject.size).to eq(grouped_organizations.values.flatten.size)
        expect(subject.map(&:percentage).sum).to eq(100)
      end
    end

    context 'when portfolio diversity is mixed' do
      let(:portfolio_diversity) { 'mixed' }
      let(:organizations_count) { 3 }
      let(:grouped_organizations) { { 'cause_area_1' => [organization_double, organization_double, organization_double], 'cause_area_2' => [organization_double, organization_double, organization_double] } }

      it 'returns allocations with 3 organizations per cause area' do
        expect(subject.size).to eq(grouped_organizations.values.flatten.size)
        expect(subject.map(&:percentage).sum).to eq(100)
      end
    end

    context 'when portfolio diversity is broad' do
      let(:portfolio_diversity) { 'broad' }
      let(:organizations_count) { 4 }
      let(:grouped_organizations) { { 'cause_area_1' => [organization_double, organization_double, organization_double, organization_double], 'cause_area_2' => [organization_double, organization_double, organization_double, organization_double] } }

      it 'returns allocations with 4 organizations per cause area' do
        expect(subject.size).to eq(grouped_organizations.values.flatten.size)
        expect(subject.map(&:percentage).sum).to eq(100)
      end
    end

    context 'when there is only one cause area' do
      let(:portfolio_diversity) { 'focused' }
      let(:organizations_count) { 1 }
      let(:grouped_organizations) { { 'single_cause_area' => [organization_double, organization_double, organization_double] } }

      before do
        organizations.each { |org| allow(org).to receive(:cause_area).and_return('single_cause_area') }
      end

      it 'returns allocations with an additional organization' do
        expect(subject.size).to eq(grouped_organizations.values.flatten.size)
        expect(subject.map(&:percentage).sum).to eq(100)
      end
    end

    context 'when there are no organizations' do
      let(:portfolio_diversity) { 'focused' }
      let(:organizations) { [] }
      let(:organizations_count) { 0 }
      let(:grouped_organizations) { {} }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when the number of organizations is less than required' do
      let(:portfolio_diversity) { 'broad' }
      let(:organizations) { create_list(:organization, 3) }
      let(:organizations_count) { 3 }
      let(:grouped_organizations) { { 'cause_area_1' => [organization_double, organization_double, organization_double] } }

      it 'returns allocations for available organizations' do
        expect(subject.size).to eq(grouped_organizations.values.flatten.size)
        expect(subject.map(&:percentage).sum).to eq(100)
      end
    end

    context 'when organizations are sampled' do
      let(:portfolio_diversity) { 'mixed' }
      let(:organizations_count) { 3 }
      let(:grouped_organizations) { { 'cause_area_1' => [organization_double, organization_double, organization_double], 'cause_area_2' => [organization_double, organization_double, organization_double] } }

      it 'samples organizations per cause area' do
        grouped_organizations.each do |cause_area, orgs|
          expect(orgs).to receive(:sample).with(4).and_return(orgs)
        end
        subject
      end
    end
  end
end
