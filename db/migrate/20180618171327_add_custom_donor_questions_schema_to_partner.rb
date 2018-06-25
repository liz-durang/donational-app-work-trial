class AddCustomDonorQuestionsSchemaToPartner < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :donor_questions_schema, :jsonb
  end
end
