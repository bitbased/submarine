class TaskCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
    
  belongs_to :task_category

  has_many :project_task_category_assignments, :foreign_key => 'task_category_id'

  has_many :harvest_task_categories, :foreign_key => 'task_category_id'
  #has_and_belongs_to_many :contacts

  attr_accessible :active, :archived_on, :is_default, :audit_log, :change_time, :data, :deleted_at, :name, :history, :locked_on, :notes, :password_digest, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON


  def serializable_hash(options={})
    options[:only] = [:id, :name, :is_default]
    super(options)
  end
  def as_json(options={})
    super(options).reject { |k, v| v.nil? }
  end

  def harvest_id
    harvest_task_categories.first.harvest_id rescue nil
  end

  def to_s
    name
  end

end
