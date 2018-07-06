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
    end

    def execute
      partner.update!(updateable_attributes)
    end

    def updateable_attributes
      inputs.except(:partner)
    end
  end
end
