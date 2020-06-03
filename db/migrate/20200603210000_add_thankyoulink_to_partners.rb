class AddThankyoulinkToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :after_donation_thank_you_page_url, :string
  end
end
