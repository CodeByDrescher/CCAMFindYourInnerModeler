class AddProjectStatusToProgramme < ActiveRecord::Migration[5.2]
  def change
    add_column :programmes, :project_status, :string
  end
end
