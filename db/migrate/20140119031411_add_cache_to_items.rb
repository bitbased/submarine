class AddCacheToItems < ActiveRecord::Migration
  def change
    add_column :submarine_accounts, :cache, :text
    add_column :submarine_accounts, :cache_keys, :text
    add_column :submarine_accounts, :cache_time, :datetime

    add_column :activity_logs, :cache, :text
    add_column :activity_logs, :cache_keys, :text
    add_column :activity_logs, :cache_time, :datetime

    add_column :roles, :cache, :text
    add_column :roles, :cache_keys, :text
    add_column :roles, :cache_time, :datetime

    add_column :user_roles, :cache, :text
    add_column :user_roles, :cache_keys, :text
    add_column :user_roles, :cache_time, :datetime

    add_column :information, :cache, :text
    add_column :information, :cache_keys, :text
    add_column :information, :cache_time, :datetime

    add_column :information_groups, :cache, :text
    add_column :information_groups, :cache_keys, :text
    add_column :information_groups, :cache_time, :datetime

    add_column :permalinks, :cache, :text
    add_column :permalinks, :cache_keys, :text
    add_column :permalinks, :cache_time, :datetime

    add_column :tasks, :cache, :text
    add_column :tasks, :cache_keys, :text
    add_column :tasks, :cache_time, :datetime

    add_column :projects, :cache, :text
    add_column :projects, :cache_keys, :text
    add_column :projects, :cache_time, :datetime

    add_column :users, :cache, :text
    add_column :users, :cache_keys, :text
    add_column :users, :cache_time, :datetime

    add_column :project_participants, :cache, :text
    add_column :project_participants, :cache_keys, :text
    add_column :project_participants, :cache_time, :datetime

    add_column :clients, :cache, :text
    add_column :clients, :cache_keys, :text
    add_column :clients, :cache_time, :datetime

    add_column :contacts, :cache, :text
    add_column :contacts, :cache_keys, :text
    add_column :contacts, :cache_time, :datetime

    add_column :task_categories, :cache, :text
    add_column :task_categories, :cache_keys, :text
    add_column :task_categories, :cache_time, :datetime

    add_column :time_entries, :cache, :text
    add_column :time_entries, :cache_keys, :text
    add_column :time_entries, :cache_time, :datetime

    add_column :expense_categories, :cache, :text
    add_column :expense_categories, :cache_keys, :text
    add_column :expense_categories, :cache_time, :datetime

    add_column :expense_entries, :cache, :text
    add_column :expense_entries, :cache_keys, :text
    add_column :expense_entries, :cache_time, :datetime

    add_column :invoice_categories, :cache, :text
    add_column :invoice_categories, :cache_keys, :text
    add_column :invoice_categories, :cache_time, :datetime
  end
end
