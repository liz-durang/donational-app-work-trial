require 'rails_helper'

RSpec.describe Partners::GetChapterOptionsByPartner, type: :query do
  let(:partner) { create(:partner, donor_questions_schema: { 'questions' => [{ 'name' => 'chapter', 'options' => ['Option 1', 'Option 2'] }] }) }
  let(:partner_without_chapter) { create(:partner, donor_questions_schema: { 'questions' => [{ 'name' => 'other', 'options' => ['Option 3'] }] }) }
  let(:partner_without_questions) { create(:partner, donor_questions_schema: { 'questions' => [] }) }

  describe '#call' do
    subject { described_class.new.call(id: partner_id) }

    context 'when the id is present' do
      let(:partner_id) { partner.id }

      it 'returns the chapter options for the given partner' do
        expect(subject).to eq(['Option 1', 'Option 2'])
      end
    end

    context 'when the partner does not have chapter options' do
      let(:partner_id) { partner_without_chapter.id }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the partner does not have any questions' do
      let(:partner_id) { partner_without_questions.id }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the id is blank' do
      let(:partner_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the partner with the given id does not exist' do
      let(:partner_id) { -1 }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
