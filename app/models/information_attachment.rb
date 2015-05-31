class InformationAttachment < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :information
  belongs_to :group, class_name: "InformationGroup"
  belongs_to :project
  belongs_to :contact
  belongs_to :client
  belongs_to :user
  belongs_to :task

  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :history, :locked_on, :notes, :permalog, :priority, :state, :sync, :sync_time, :visible
end
