class CreateActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.references :submarine_account

      t.references :user
      t.references :parent
      t.string :activity
      t.text :message
      t.text :description
      t.text :show_to
      t.text :starred_by
      t.text :viewed_by
      t.text :dismissed_by
      t.datetime :activity_time
      t.datetime :dismiss_at
      t.text :notes
      t.text :history
      t.boolean :visible
      t.boolean :running
      t.integer :progress, :default => 0
      t.datetime :change_time
      t.datetime :deleted_at
      t.text :data
      t.string :resource_type
      t.integer :resource_id
      t.text :resource_name
      t.text :resource_data
      t.text :resource_state

      t.timestamps
    end
    add_index :activity_logs, :user_id
    add_index :activity_logs, :parent_id
    add_index :activity_logs, :resource_id
    add_index :activity_logs, :resource_type
    add_index :activity_logs, :submarine_account_id
  end
end
