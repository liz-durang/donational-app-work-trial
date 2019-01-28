require "rails_helper"

RSpec.describe ContributionsSummaryMailer, type: :mailer do
  describe "notify" do
    let(:params) do
      {
        contributions: contributions,
        year: 2018,
        donor: build(:donor, first_name: 'Joe', last_name: 'Donator', email: 'donor@example.org'),
        partner: partner
      }
    end
    let(:mail) { ContributionsSummaryMailer.with(params).notify }

    context "when the donor is affiliated with a Partner" do
      let(:partner) { build(:partner, name: 'Example Partner') }
      let(:contributions) do
        [
          build(:contribution, amount_cents: 1000, tips_cents: 0, processed_at: Date.new(2018, 2, 10)),
          build(:contribution, amount_cents: 1625, tips_cents: 0, processed_at: Date.new(2018, 10, 1)),
          build(:contribution, amount_cents: 1525, tips_cents: 0, processed_at: Date.new(2018, 7, 1)),
          build(:contribution, amount_cents: 1100, tips_cents: 0, processed_at: Date.new(2018, 4, 1)),
        ]
      end

      it "renders the headers" do
        expect(mail.subject).to eq("It's Tax-Time! Here is your Example Partner contribution summary for 2018")
        expect(mail.to).to eq(["donor@example.org"])
        expect(mail.from).to eq(["receipts@donational.org"])
      end

      it "renders the body" do
        expect(mail.body.encoded).to include("Your 2018 contributions to your Example Partner charity portfolio")
        expect(mail.body.encoded).to include("Powered by Donational.org")
        expect(mail.body.encoded).to include("Hey Joe Donator,")
        expect(mail.body.encoded).to include("In 2018, you donated a total of $52.50 to your charitable portfolio!")

        expect(mail.body.encoded).to match(
          Regexp.new(
            [
              "Date: February 10th, 2018",
              "\\$10.00",
              "Date: April 1st, 2018",
              "\\$11.00",
              "Date: July 1st, 2018",
              "\\$15.25",
              "Date: October 1st, 2018",
              "\\$16.25"
            ].join('.*')
          )
        )
      end
    end

    context "when the donor not affiliated with a Partner" do
      let(:partner) { nil }
      let(:contributions) do
        [
          build(:contribution, amount_cents: 1000, tips_cents: 100, processed_at: Time.new(2018, 12, 31, 1)),
          build(:contribution, amount_cents: 2000, tips_cents: 0, processed_at: Time.new(2018, 12, 31, 4)),
        ]
      end

      it "renders the headers" do
        expect(mail.subject).to eq("It's Tax-Time! Here is your Donational.org contribution summary for 2018")
        expect(mail.to).to eq(["donor@example.org"])
        expect(mail.from).to eq(["receipts@donational.org"])
      end

      it "renders the body" do
        expect(mail.body.encoded).to include("Your 2018 contributions to your Donational.org charity portfolio")
        expect(mail.body.encoded).to include("Hey Joe Donator,")
        expect(mail.body.encoded).to include("In 2018, you donated a total of $31.00 to your charitable portfolio!")

        expect(mail.body.encoded).to match(
          Regexp.new(
            [
              "Date: December 31st, 2018",
              "\\$11.00",
              "Date: December 31st, 2018",
              "\\$20.00"
            ].join('.*')
          )
        )
      end
    end
  end
end
