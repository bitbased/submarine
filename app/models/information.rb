class Information < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :parent, class_name: "Information"
  belongs_to :primary_group, class_name: "InformationGroup"

  has_many :children, :class_name => 'Information', :foreign_key => 'parent_id'
  #has_many :children, class_name: "Information", :through => :child_links

  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :description, :global, :history, :items, :locked_on, :name, :notes, :permalog, :priority, :secure_items, :security_scheme, :state, :sync, :sync_time, :tags, :template, :visible
end
