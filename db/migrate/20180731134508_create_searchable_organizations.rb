class CreateSearchableOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :searchable_organizations, id: false do |t|
      t.string :ein, null: false
      t.string :name, null: false, index: true
      t.string :ico
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.string :org_group
      t.string :subsection
      t.string :affiliation
      t.string :classification
      t.string :ruling
      t.string :deductibility
      t.string :foundation
      t.string :activity
      t.string :organization
      t.string :status
      t.string :tax_period
      t.string :asset_cd
      t.string :income_cd
      t.string :filing_req_cd
      t.string :pf_filing_req_cd
      t.string :acct_pd
      t.string :asset_amt
      t.string :income_amt
      t.string :revenue_amt
      t.string :ntee_cd
      t.string :sort_name
    end

    add_index :searchable_organizations, :ein, unique: true
  end
end
