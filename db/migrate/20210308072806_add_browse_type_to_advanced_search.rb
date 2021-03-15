class AddBrowseTypeToAdvancedSearch < ActiveRecord::Migration[5.2]
  def change
    add_column :advanced_searches, :browse_type, :string
  end
end
