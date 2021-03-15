class AddTargetCompletionToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :target_completion, :date
  end
end
