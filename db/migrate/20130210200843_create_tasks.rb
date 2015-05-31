class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :parent
      t.references :project
      t.text :tags
      t.references :client
      t.references :contact
      t.string :name
      t.string :status, :default => :new
      t.text :focus
      t.integer :progress
      t.text :notes
      t.datetime :open_date
      t.datetime :start_date
      t.datetime :due_date
      t.datetime :close_date
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
    add_index :tasks, :parent_id
    add_index :tasks, :project_id
    add_index :tasks, :client_id
    add_index :tasks, :contact_id
    add_index :tasks, :submarine_account_id
  end
end
