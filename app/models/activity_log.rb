class ActivityLog < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :user
  belongs_to :parent, :class_name => "ActivityLog"
  attr_accessible :user_id, :running, :progress, :user, :parent_id, :activity, :activity_time, :dismissed_by, :data, :deleted_at, :description, :history, :message, :notes, :resource_data, :resource_id, :resource_name, :resource_state, :resource_type, :show_to, :starred_by, :viewed_by, :updated_at, :visible, :dismiss_at

  serialize :data, JSON

end
