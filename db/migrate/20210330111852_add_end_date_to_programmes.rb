class AddEndDateToProgrammes < ActiveRecord::Migration[5.2]
  def change
    add_column :programmes, :end_date, :date
  end
end
