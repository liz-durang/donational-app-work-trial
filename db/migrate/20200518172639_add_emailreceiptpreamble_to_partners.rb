class AddEmailreceiptpreambleToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :email_receipt_preamble, :text
  end
end
