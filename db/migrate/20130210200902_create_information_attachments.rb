class CreateInformationAttachments < ActiveRecord::Migration
  def change
    create_table :information_attachments do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :information
      t.references :group
      t.references :project
      t.references :contact
      t.references :client
      t.references :user
      t.references :task
      t.string :notes
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
    add_index :information_attachments, :information_id
    add_index :information_attachments, :group_id
    add_index :information_attachments, :project_id
    add_index :information_attachments, :contact_id
    add_index :information_attachments, :client_id
    add_index :information_attachments, :user_id
    add_index :information_attachments, :task_id
    add_index :information_attachments, :submarine_account_id
  end
end
