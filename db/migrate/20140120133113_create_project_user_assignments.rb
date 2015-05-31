class CreateProjectUserAssignments < ActiveRecord::Migration
  def change
    create_table :project_user_assignments do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :project
      t.references :user
      t.string :status
      t.text :notes
      t.text :data
      t.string :state
      t.text :sync
      t.datetime :sync_time
      t.datetime :change_time
      t.text :history
      t.datetime :deleted_at
      t.datetime :archived_on

      t.boolean :is_project_manager, :default => false
      t.decimal :hourly_rate

      t.boolean :active, :default => true
      t.datetime :locked_on
      t.boolean :visible, :default => true
      t.text :audit_log
      t.text :permalog
      t.boolean :draft
      t.text :drafting
      t.float :priority

      t.text :cache
      t.text :cache_keys
      t.datetime :cache_time

      t.timestamps
    end
    add_index :project_user_assignments, :project_id
    add_index :project_user_assignments, :user_id
    add_index :project_user_assignments, :submarine_account_id
  end
end