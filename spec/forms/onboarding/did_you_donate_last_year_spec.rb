require 'rails_helper'

RSpec.describe Onboarding::DidYouDonateLastYear, type: :model do
  subject(:step) { Onboarding::DidYouDonateLastYear.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is 'yes'" do
      it "sets the Donor's #donated_prior_year to true" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, donated_prior_year: true)

        step.process!('yes')
      end
    end

    context "when the response is 'no'" do
      it "sets the Donor's #donated_prior_year to false" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, donated_prior_year: false)

        step.process!('no')
      end
    end

    context "when the response is not 'yes' or 'no'" do
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
