class CreateInformation < ActiveRecord::Migration
  def change
    create_table :information do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :parent
      t.references :primary_group
      t.string :name
      t.string :description
      t.string :tags
      t.text :template
      t.string :notes
      t.text :items
      t.text :secure_items
      t.text :security_scheme
      t.boolean :global
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
    add_index :information, :parent_id
    add_index :information, :primary_group_id
    add_index :information, :submarine_account_id
  end
end
