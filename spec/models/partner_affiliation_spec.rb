require 'rails_helper'

RSpec.describe PartnerAffiliation, type: :model do 
  describe 'associations' do
    it { should belong_to(:partner) }
    it { should belong_to(:donor) }
    it { should belong_to(:campaign).optional }
    it { should belong_to(:referred_by_donor).class_name('Donor').optional }
  end

  describe 'delegations' do
    it { should delegate_method(:title).to(:campaign).with_prefix.allow_nil }
    it { should delegate_method(:name).to(:partner).with_prefix }
  end

  describe 'methods' do
    describe '#donor_responses' do
      let(:partner) { create(:partner) }
      let(:donor) { create(:donor) }
      let(:campaign) { create(:campaign) }
      let(:custom_donor_info) { { 'question1' => 'answer1', 'question2' => 'answer2' } }
      let(:partner_affiliation) { create(:partner_affiliation, partner: partner, donor: donor, campaign: campaign, custom_donor_info: custom_donor_info) }

      it 'returns an array of DonorResponse objects' do
        allow(partner).to receive(:donor_questions).and_return([OpenStruct.new(name: 'question1'), OpenStruct.new(name: 'question2')])
        responses = partner_affiliation.donor_responses

        expect(responses.size).to eq(2)
        expect(responses.first).to be_a(PartnerAffiliation::DonorResponse)
        expect(responses.first.question.name).to eq('question1')
        expect(responses.first.value).to eq('answer1')
      end
    end

    describe '#reindex_donor' do
      let(:donor) { create(:donor) }
      let(:partner_affiliation) { create(:partner_affiliation, donor: donor) }

      it 'calls reindex on the donor' do
        expect(donor).to receive(:reindex).twice
        partner_affiliation.reindex_donor
      end
    end
  end

  describe PartnerAffiliation::DonorResponse do
    let(:question) { OpenStruct.new(name: 'question1') }
    let(:value) { 'answer1' }
    let(:donor_response) { described_class.new(question: question, value: value) }

    it 'initializes with a question and value' do
      expect(donor_response.question).to eq(question)
      expect(donor_response.value).to eq(value)
    end
  end
end
