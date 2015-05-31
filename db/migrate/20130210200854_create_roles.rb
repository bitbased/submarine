class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.string :name
      t.string :notes
      t.string :type
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
    add_index :roles, :submarine_account_id
  end
end
