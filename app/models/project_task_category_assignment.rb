class ProjectTaskCategoryAssignment < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  has_many :harvest_task_assignments, :foreign_key => 'project_task_category_assignment_id'

  belongs_to :project
  belongs_to :task_category

  attr_accessible :active, :archived_on, :audit_log, :billable, :billed, :category, :change_time, :data, :date, :deleted_at, :history, :idle, :locked_on, :notes, :permalog, :priority, :state, :status, :sync, :sync_time, :tags, :visible       ,      :task_category_id, :base_project_id, :base_task_id, :project_id, :task_id, :client_id, :contact_id, :user_id, :billable_project, :billable_project_id

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  after_save ActivityWrapper.new(["active", "user_id", "task_category_id", "deleted_at", "project_id", "task_id", "billed", "billable", "notes", "date", "category", "base_project_id", "base_task_id", "active"])
  #after_initialize ActivityWrapper.new

  def serializable_hash(options={})
    options[:only] = [:id, :project_id, :task_category_id]
    options[:methods] = [:task_category_name]
    super(options)
  end


  def harvest_id
    harvest_task_assignments.first.harvest_id rescue nil
  end


  def task_category_name
    task_category.name rescue nil
  end

  def to_s
    (task_category ? task_category.name.to_s : "")
  end

end
