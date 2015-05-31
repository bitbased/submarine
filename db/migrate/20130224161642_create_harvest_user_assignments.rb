class CreateHarvestUserAssignments < ActiveRecord::Migration
  def change
    create_table :harvest_user_assignments do |t|
      t.references :submarine_account

      t.string :slug
      
      t.references :project_participant
      t.integer :harvest_id
      t.text :cache
      t.text :data
      t.string :state
      t.text :sync
      t.datetime :sync_time
      t.datetime :change_time
      t.text :history
      t.datetime :deleted_at
      t.datetime :archived_on
      t.boolean :active
      t.datetime :locked_on
      t.boolean :visible
      t.text :audit_log
      t.text :permalog
      t.boolean :draft
      t.text :drafting
      t.float :priority

      t.timestamps
    end
    add_index :harvest_user_assignments, :project_participant_id
    add_index :harvest_user_assignments, :submarine_account_id
  end
end
