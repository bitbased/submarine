class Task < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :parent, class_name: "Task"
  belongs_to :project
  belongs_to :client
  belongs_to :contact
  attr_accessible :active, :archived_on, :audit_log, :change_time, :close_date, :data, :deleted_at, :due_date, :focus, :history, :locked_on, :name, :notes, :open_date, :permalog, :priority, :progress, :start_date, :state, :status, :sync, :sync_time, :tags, :visible

  def to_s
    name
  end

end
