class CreateAdvancedSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :advanced_searches do |t|
      t.string :keywords
      t.string :search_type
      t.date :min_due_date
      t.date :max_due_date
      t.string :institution
      t.string :discipline
      t.string :tool
      t.string :city
      t.string :expertise

      t.timestamps
    end
  end
end
