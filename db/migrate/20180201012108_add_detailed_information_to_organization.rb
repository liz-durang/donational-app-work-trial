class AddDetailedInformationToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :mission, :text
    add_column :organizations, :context, :text
    add_column :organizations, :impact, :text
    add_column :organizations, :why_you_should_care, :text
    add_column :organizations, :website_url, :string
    add_column :organizations, :annual_report_url, :string
    add_column :organizations, :financials_url, :string
    add_column :organizations, :form_990_url, :string
    add_column :organizations, :recommended_by, :string, array: true, default: '{}'
  end
end
