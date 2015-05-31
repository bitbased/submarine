class Role < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :history, :locked_on, :name, :notes, :permalog, :priority, :state, :sync, :sync_time, :type, :visible
end
