require "rails_helper"

RSpec.describe ContributionsSummaryMailer, type: :mailer do
  describe "notify" do
    let(:params) do
      {
        contributions: contributions,
        year: 2018,
        donor: create(:donor, first_name: 'Joe', last_name: 'Donator', email: 'donor@example.org'),
        partner: partner
      }
    end
    let(:mail) { ContributionsSummaryMailer.with(params).notify }

    let(:amf) { create(:organization, name: 'Against Malaria Foundation') }
    let(:gd) { create(:organization, name: 'Give Directly') }
    let(:end_fund) { create(:organization, name: 'The End Fund') }
    let(:dollars) { Money::Currency.new('usd') }
    let(:pounds) { Money::Currency.new('gbp') }
    let(:partner) { create(:partner,
      name: 'Example Partner',
      currency: currency.iso_code,
      receipt_first_paragraph: "First Paragraph",
      receipt_second_paragraph: "Second Paragraph",
      receipt_tax_info: "Tax Info",
      receipt_charity_name: "Charity Name") }
    let(:contributions) do
      [
        create(:contribution_with_donations_to_organizations, amount_cents: 1000, tips_cents: 0, processed_at: Date.new(2018, 2, 10), organizations: [gd, amf]),
        create(:contribution_with_donations_to_organizations, amount_cents: 1625, tips_cents: 0, processed_at: Date.new(2018, 10, 1), organizations: [gd]),
        create(:contribution_with_donations_to_organizations, amount_cents: 1525, tips_cents: 0, processed_at: Date.new(2018, 7, 1), organizations: [end_fund]),
        create(:contribution_with_donations_to_organizations, amount_cents: 1100, tips_cents: 0, processed_at: Date.new(2018, 4, 1), organizations: [gd, amf])
      ]
    end

    context "when the donor is affiliated with US Partner" do
      let(:currency) { dollars }

      it "renders the headers" do
        expect(mail.subject).to eq("It's Tax-Time! Here is your Example Partner contribution summary for 2018")
        expect(mail.to).to eq(["donor@example.org"])
        expect(mail.from).to eq(["receipts@donational.org"])
      end

      it "renders the body" do
        expect(mail.body.encoded).to include("Your 2018 contributions to your Example Partner charity portfolio")
        expect(mail.body.encoded).to include("Hey Joe,")
        expect(mail.body.encoded).to include(
          "In 2018, you donated a total of <b>#{Money.new(5250, currency).format}</b> to your Example Partner portfolio!"
        )

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

      it "displays a summary of all the organizations a donor contributed to" do
        expect(mail.body.encoded).to include("Your contributions in 2018 supported 3 charities:")
        expect(mail.body.encoded).to include("Against Malaria Foundation")
        expect(mail.body.encoded).to include("Give Directly")
        expect(mail.body.encoded).to include("The End Fund")
        expect(mail.body.encoded).to include("First Paragraph")
        expect(mail.body.encoded).to include("Second Paragraph")
        expect(mail.body.encoded).to include("Tax Info")
      end
    end

    context "when the donor is affiliated with UK Partner" do
      let(:currency) { pounds }

      it "renders the body" do
        expect(mail.body.encoded).to include(
          "In 2018, you donated a total of <b>#{Money.new(5250, currency).format}</b> to your Example Partner portfolio!"
        )
      end
    end
  end
end
