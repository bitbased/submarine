class AddAssociationDatesToProjects < ActiveRecord::Migration
  def change

    add_column :projects, :update_associations, :boolean
    add_column :projects, :update_associations_time, :datetime
    add_column :projects, :update_associations_times, :text

  end
end
