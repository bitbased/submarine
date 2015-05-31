class InformationGroup < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :parent, class_name: "InformationGroup"
  belongs_to :information
  has_many :information

  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :description, :history, :locked_on, :name, :notes, :permalog, :primary, :priority, :state, :sync, :sync_time, :template, :visible
end
