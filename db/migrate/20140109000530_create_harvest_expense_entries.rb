class CreateHarvestExpenseEntries < ActiveRecord::Migration
  def change
    create_table :harvest_expense_entries do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :expense_entry
      t.integer :harvest_id
      t.string :harvest_project_id
      t.string :harvest_user_id
      t.text :cache
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
    add_index :harvest_expense_entries, :expense_entry_id
    add_index :harvest_expense_entries, :submarine_account_id
  end
end
