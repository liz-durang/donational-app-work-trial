require 'rails_helper'

RSpec.describe ProcessScheduledContributions, type: :job do
  let(:contribution1) { double('Contribution') }
  let(:contribution2) { double('Contribution') }
  let(:unprocessed_contributions) { [contribution1, contribution2] }

  before do
    allow(Contributions::GetUnprocessedContributions).to receive(:call).and_return(unprocessed_contributions)
    allow(Contributions::ProcessContribution).to receive(:run)
  end


  it 'processes each unprocessed scheduled contribution' do
    expect(Contributions::ProcessContribution).to receive(:run).with(contribution: contribution1)
    expect(Contributions::ProcessContribution).to receive(:run).with(contribution: contribution2)

    described_class.perform_inline
  end

  it 'logs the number of processed contributions' do
    expect { described_class.perform_inline }.to output("Processed 2 contributions\n").to_stdout
  end
end
