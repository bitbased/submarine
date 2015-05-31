class AddSecondaryClientToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :secondary_client_id, :integer
    add_index :projects, :secondary_client_id
  end
end
