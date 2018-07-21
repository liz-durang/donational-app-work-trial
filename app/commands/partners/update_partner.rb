module Partners
  class UpdatePartner < ApplicationCommand
    required do
      model :partner
    end

    optional do
      string :name
      string :website_url
      string :description
      string :payment_processor_account_id
      string :logo
    end

    def execute
      partner.logo.attach(logo)
      partner.update!(
        name: name,
        website_url: website_url,
        description: description,
        payment_processor_account_id: payment_processor_account_id
      )
    end
  end
end
