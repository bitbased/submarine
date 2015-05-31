class CreateHarvestProjects < ActiveRecord::Migration
  def change
    create_table :harvest_projects do |t|
      t.references :submarine_account
      
      t.string :slug
      
      t.boolean :refresh_associations

      t.references :project
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
      t.boolean :active
      t.datetime :locked_on
      t.boolean :visible
      t.text :audit_log
      t.text :permalog
      t.boolean :draft
      t.text :drafting
      t.float :priority

      t.timestamps
    end
    add_index :harvest_projects, :project_id
    add_index :harvest_projects, :submarine_account_id
  end
end
