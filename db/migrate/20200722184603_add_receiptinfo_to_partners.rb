class AddReceiptinfoToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :receipt_first_paragraph, :text
    add_column :partners, :receipt_second_paragraph, :text
    add_column :partners, :receipt_tax_info, :text
    add_column :partners, :receipt_charity_name, :string
  end
end
