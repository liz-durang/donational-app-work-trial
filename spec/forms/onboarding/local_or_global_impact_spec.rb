require 'rails_helper'

RSpec.describe Onboarding::LocalOrGlobalImpact, type: :model do
  subject(:step) { Onboarding::LocalOrGlobalImpact.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is 'local'" do
      it "sets the Donor's preferences to local impact organizations only" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_local_organizations: true,
          include_global_organizations: false
        )

        step.process!('local')
      end
    end

    context "when the response is 'both'" do
      it "sets the Donor's preferences to local impact and global impact organizations" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_local_organizations: true,
          include_global_organizations: true
        )

        step.process!('both')
      end
    end

    context "when the response is 'global'" do
      it "sets the Donor's preferences to global impact organizations only" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_local_organizations: false,
          include_global_organizations: true
        )

        step.process!('global')
      end
    end

    context "when the response is something else" do
      it "adds errors to the form" do
        step.process!(123)

        expect(step.errors.messages[:response]).to include('123 is not one of the allowed responses')
      end

      it "doesn't touch the Donor" do
        expect(Donors::UpdateDonor).not_to receive(:run!)

        step.process!(true)
      end
    end
  end
end
