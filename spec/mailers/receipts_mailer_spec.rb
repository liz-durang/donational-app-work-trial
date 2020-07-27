require "rails_helper"

RSpec.describe ReceiptsMailer, type: :mailer do
  describe "send_receipt" do
    let(:dollars) { Money::Currency.new('usd') }
    let(:pounds) { Money::Currency.new('gbp') }

    let(:amf) { create(:organization, name: 'Against Malaria Foundation') }
    let(:gd) { create(:organization, name: 'Give Directly') }

    let(:partner) { create(:partner,
      name: 'Example Partner',
      currency: currency.iso_code,
      receipt_first_paragraph: "First Paragraph",
      receipt_second_paragraph: "Second Paragraph",
      receipt_tax_info: "Tax Info",
      receipt_charity_name: "Charity Name") }
    let(:contribution) { create(:contribution_with_donations_to_organizations,
      amount_cents: 1000,
      tips_cents: 0,
      processed_at: Date.new(2018, 2, 10),
      organizations: [gd, amf],
      donor: create(:donor, first_name: 'Joe', last_name: 'Donator', email: 'donor@example.org')) }
    let(:payment_method) { create(:payment_method, last4: "1234") }
    
    let(:mail) { ReceiptsMailer.send_receipt(contribution, payment_method, partner) }

    context "when the donor is affiliated with US Partner" do

      let(:currency) { dollars }

      it "renders the headers" do
        expect(mail.subject).to eq("Your Tax-Deductible Receipt for your Example Partner charity portfolio")
        expect(mail.to).to eq(["donor@example.org"])
        expect(mail.from).to eq(["receipts@donational.org"])
      end

      it "displays a receipt" do
        expect(mail.body.encoded).to include("Against Malaria Foundation")
        expect(mail.body.encoded).to include("Give Directly")
        expect(mail.body.encoded).to include("1234")
        expect(mail.body.encoded).to include("First Paragraph")
        expect(mail.body.encoded).to include("Second Paragraph")
        expect(mail.body.encoded).to include("Tax Info")
      end
    end

    context "when the donor is affiliated with UK Partner" do
      let(:currency) { pounds }

      it "renders the body" do
        expect(mail.body.encoded).to include(
          "#{Money.new(1000, currency).format}"
        )
      end
    end
  end
end
