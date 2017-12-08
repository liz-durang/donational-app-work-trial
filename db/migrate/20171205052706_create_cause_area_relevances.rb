class CreateCauseAreaRelevances < ActiveRecord::Migration[5.1]
  def change
    create_table :cause_area_relevances, id: :uuid do |t|
      t.references :donor, foreign_key: true, type: :uuid
      t.integer :global_health
      t.integer :poverty_and_income_inequality
      t.integer :climate_and_environment
      t.integer :animal_welfare
      t.integer :hunger_nutrition_and_safe_water
      t.integer :women_and_girls
      t.integer :immigration_and_refugees
      t.integer :education
      t.integer :economic_development

      t.timestamps
    end
  end
end
