class AddApiKeyToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :api_key, :string
  end
end
