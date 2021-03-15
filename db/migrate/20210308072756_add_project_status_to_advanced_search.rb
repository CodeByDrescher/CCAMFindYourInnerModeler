class AddProjectStatusToAdvancedSearch < ActiveRecord::Migration[5.2]
  def change
    add_column :advanced_searches, :project_status, :string
  end
end
