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
      partner.update!(updateable_attributes)
      partner.logo.attach(logo) if logo.present?
    end

    def updateable_attributes
      inputs.except(:partner)
    end
  end
end
