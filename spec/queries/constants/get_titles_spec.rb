require 'rails_helper'

RSpec.describe Constants::GetTitles, type: :query do
  describe '#call' do
    subject { described_class.new.call }

    it 'returns the correct titles' do
      expect(subject).to eq(%w[Mr Mrs Ms Mx])
    end

    it 'returns a frozen array' do
      expect(subject).to be_frozen
    end
  end
end
