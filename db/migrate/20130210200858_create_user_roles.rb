class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :user
      t.references :role
      t.references :project
      t.references :client
      t.references :task
      t.text :data
      t.string :state
      t.text :sync
      t.datetime :sync_time
      t.datetime :change_time
      t.text :history
      t.datetime :deleted_at
      t.datetime :archived_on
      t.boolean :active, :default => true
      t.datetime :locked_on
      t.boolean :visible, :default => true
      t.text :audit_log
      t.text :permalog
      t.boolean :draft
      t.text :drafting
      t.float :priority

      t.timestamps
    end
    add_index :user_roles, :user_id
    add_index :user_roles, :role_id
    add_index :user_roles, :project_id
    add_index :user_roles, :client_id
    add_index :user_roles, :task_id
    add_index :user_roles, :submarine_account_id
  end
end
