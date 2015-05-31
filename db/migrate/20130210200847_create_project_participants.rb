class CreateProjectParticipants < ActiveRecord::Migration
  def change
    create_table :project_participants do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.references :project
      t.references :contact
      t.references :user
      t.string :status
      t.text :notes
      t.text :data
      t.string :state
      t.text :sync
      t.datetime :sync_time
      t.datetime :change_time
      t.text :history
      t.datetime :deleted_at
      t.datetime :archived_on

      t.boolean :is_manager, :default => false
      t.boolean :is_lead, :default => false

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
    add_index :project_participants, :project_id
    add_index :project_participants, :contact_id
    add_index :project_participants, :user_id
    add_index :project_participants, :submarine_account_id
  end
end
