class ModifyReferencesOnHarvestUserAssignments < ActiveRecord::Migration
  def change
    add_column :harvest_user_assignments, :project_user_assignment_id, :integer
    add_index :harvest_user_assignments, :project_user_assignment_id
  end
end
