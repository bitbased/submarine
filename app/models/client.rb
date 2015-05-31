class Client < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid# :recover_dependent_associations => false
  
  # :dependent_recovery_window => 10.minutes *** defaults to 2.minutes

  belongs_to :parent, :class_name => "Client"
  has_many :contacts

  has_many :harvest_clients, :foreign_key => 'client_id'
  #has_and_belongs_to_many :contacts

  has_many :projects

  attr_accessible :active, :details, :archived_on, :audit_log, :change_time, :data, :deleted_at, :history, :locked_on, :name, :notes, :permalog, :priority, :state, :sync, :sync_time, :tags, :visible, :parent_id, :parent

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  after_save ActivityWrapper.new(["active", "name", "deleted_at", "parent_id", "notes", "details", "tags", "visible", "sync"])

  def serializable_hash(options={})
    options[:only] = [:id, :name]
    super(options)
  end

  def to_s
    name
  end
end
