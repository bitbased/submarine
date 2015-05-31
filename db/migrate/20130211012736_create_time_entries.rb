class CreateTimeEntries < ActiveRecord::Migration
  def change
    create_table :time_entries do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :base_project
      t.references :base_task
      t.references :project
      t.references :task
      t.references :task_category
      t.boolean :billable
      t.boolean :billed
      t.datetime :date
      t.datetime :start_time
      t.datetime :end_time
      t.float :idle, :default => 0
      t.float :hours, :default => 0
      t.datetime :timer_started_at
      t.text :timers
      t.string :category
      t.text :tags
      t.references :client
      t.references :contact
      t.references :user
      t.string :status, :default => :new
      t.text :notes
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
    add_index :time_entries, :project_id
    add_index :time_entries, :task_category_id
    add_index :time_entries, :base_project_id
    add_index :time_entries, :task_id
    add_index :time_entries, :client_id
    add_index :time_entries, :contact_id
    add_index :time_entries, :user_id
    add_index :time_entries, :submarine_account_id
  end
end
