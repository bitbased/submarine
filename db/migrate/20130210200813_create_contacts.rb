class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.references :submarine_account
      
      t.string :slug

      t.references :parent
      t.references :client
      t.string :first_name
      t.string :last_name
      t.text :tags
      t.string :company
      t.string :title
      t.string :email
      t.string :office_number
      t.string :mobile_number
      t.string :fax_number
      t.text :notes
      t.boolean :shared
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
    add_index :contacts, :client_id
    add_index :contacts, :parent_id
    add_index :contacts, :submarine_account_id
  end
end
