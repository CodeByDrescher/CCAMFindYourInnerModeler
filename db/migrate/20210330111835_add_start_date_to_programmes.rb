class AddStartDateToProgrammes < ActiveRecord::Migration[5.2]
  def change
    add_column :programmes, :start_date, :date
  end
end
