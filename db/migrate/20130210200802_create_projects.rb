class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.references :submarine_account
      
      t.string :slug

      t.string :code
      t.datetime :open_date
      t.datetime :start_date
      t.text :focus
      t.datetime :due_date
      t.datetime :close_date
      t.integer :progress
      t.references :parent
      t.references :client
      t.references :contact
      t.string :name
      t.text :description
      t.text :tags
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
    add_index :projects, :parent_id
    add_index :projects, :client_id
    add_index :projects, :contact_id
    add_index :projects, :submarine_account_id
  end
end
