module Partners
  class UpdatePartner < ApplicationCommand
    required do
      model :partner
    end

    optional do
      string :name
      string :website_url
      string :description, empty: true
      string :email_receipt_preamble, empty: true
      string :after_donation_thank_you_page_url, empty: true
      string :receipt_first_paragraph, empty: true
      string :receipt_second_paragraph, empty: true
      string :receipt_tax_info, empty: true
      string :receipt_charity_name, empty: true
      string :payment_processor_account_id
      string :logo
      string :email_banner
    end

    def execute
      partner.update!(updateable_attributes)
      partner.logo.attach(logo) if logo.present?
      partner.email_banner.attach(email_banner) if email_banner.present?
    end

    def updateable_attributes
      inputs.except(:partner)
    end
  end
end
