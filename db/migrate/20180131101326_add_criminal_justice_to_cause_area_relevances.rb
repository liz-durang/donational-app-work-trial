class AddCriminalJusticeToCauseAreaRelevances < ActiveRecord::Migration[5.1]
  def change
    add_column :cause_area_relevances, :criminal_justice, :integer
  end
end
