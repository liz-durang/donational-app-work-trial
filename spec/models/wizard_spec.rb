require 'rails_helper'

RSpec.describe Wizard, type: :model do
  let(:step_1) { double(:step_1) }
  let(:step_2) { double(:step_2) }
  let(:step_3) { double(:step_3) }
  let(:steps) { [step_1, step_2, step_3] }

  describe '#first_step' do
    it 'returns the first step' do
      wizard = Wizard.new(steps)
      expect(wizard.first_step).to eq(step_1)
    end
  end

  describe '#last_step' do
    it 'returns the last step' do
      wizard = Wizard.new(steps)
      expect(wizard.last_step).to eq(step_3)
    end
  end

  describe '#last_step?' do
    context 'when the wizard is at the last step' do
      it 'returns true' do
        wizard = Wizard.new(steps)
        wizard.next_step!
        wizard.next_step!
        expect(wizard.last_step?).to be true
      end
    end

    context 'when the wizard is not at the last step' do
      it 'returns false' do
        wizard = Wizard.new(steps)
        expect(wizard.last_step?).to be false
      end
    end
  end

  describe '#current_step' do
    it 'returns the current step' do
      wizard = Wizard.new(steps)
      expect(wizard.current_step).to eq(step_1)
      wizard.next_step!
      expect(wizard.current_step).to eq(step_2)
    end
  end

  describe '#next_step!' do
    context 'when the wizard is not at the last step' do
      it 'progresses to the next step' do
        wizard = Wizard.new(steps)
        expect(wizard.next_step!).to eq step_2
      end
    end

    context 'when the wizard is at the last step' do
      it 'returns nil' do
        wizard = Wizard.new(steps)
        wizard.next_step!
        wizard.next_step!
        expect(wizard.next_step!).to be_nil
      end
    end
  end
end
