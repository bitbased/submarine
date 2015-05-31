class CreateHarvestInvoiceCategories < ActiveRecord::Migration
  def change
    create_table :harvest_invoice_categories do |t|
      t.references :submarine_account

      t.string :slug
      
      t.references :invoice_category
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
    add_index :harvest_invoice_categories, :invoice_category_id
    add_index :harvest_invoice_categories, :submarine_account_id
  end
end
