class AddFieldsToTaskCategories < ActiveRecord::Migration
  def change

    add_column :task_categories, :is_billable, :boolean
    add_column :task_categories, :hourly_rate, :decimal
    add_column :task_categories, :is_default, :boolean

  end
end
