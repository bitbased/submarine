class CreateProjectTaskCategoryAssignments < ActiveRecord::Migration
  def change
    create_table :project_task_category_assignments do |t|
      t.references :submarine_account

      t.string :slug

      t.references :project
      t.references :task_category
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

      t.boolean :is_billable, :default => false
      t.decimal :hourly_rate
      t.decimal :budget

      t.boolean :active, :default => true
      t.datetime :locked_on
      t.boolean :visible, :default => true
      t.text :audit_log
      t.text :permalog
      t.boolean :draft
      t.text :drafting
      t.float :priority

      t.text :cache
      t.text :cache_keys
      t.datetime :cache_time

      t.timestamps
    end
    add_index :project_task_category_assignments, :project_id, :name => 'index_project_task_category_project_id'
    add_index :project_task_category_assignments, :task_category_id, :name => 'index_project_task_category_task_category_id'
    add_index :project_task_category_assignments, :submarine_account_id, :name => 'index_project_task_category_submarine_account_id'
  end
end
