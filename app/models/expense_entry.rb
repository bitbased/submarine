class ExpenseEntry < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  has_many :harvest_expense_entries, :foreign_key => 'expense_entry_id'
  
  belongs_to :billable_project, class_name: "Project"
  belongs_to :base_project, class_name: "Project"
  belongs_to :base_task, class_name: "Task"
  belongs_to :project
  belongs_to :client
  belongs_to :contact
  belongs_to :user
  belongs_to :expense_category
  attr_accessible :active, :expense_category_id, :total_cost, :units, :archived_on, :audit_log, :billable, :billed, :category, :change_time, :data, :date, :deleted_at, :history, :idle, :locked_on, :notes, :permalog, :priority, :state, :status, :sync, :sync_time, :tags, :timers, :visible       ,      :task_category_id, :base_project_id, :base_task_id, :project_id, :task_id, :client_id, :contact_id, :user_id, :billable_project, :billable_project_id

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  after_save ActivityWrapper.new(["active", "user_id", "expense_category_id", "units", "total_cost", "deleted_at", "client_id", "billable_project_id", "base_project_id", "project_id", "task_id", "billed", "billable", "notes", "date", "category", "base_project_id", "base_task_id", "active"])
  #after_initialize ActivityWrapper.new


  def serializable_hash(options={})
    options[:only] = [:id, :user_id, :project_id, :notes, :total_cost, :units, :expense_category_id, :date]
    options[:methods] = [:expense_category_name, :project_code, :project_name, :client_name]
    super(options)
  end

  def expense_category_name
    expense_category.name
  end

  def project_code
    project.code rescue nil
  end

  def project_name
    project.name rescue nil
  end

  def client_name
    project.client.name rescue nil
  end

  def secondary_client_name
    project.secondary_client.name rescue nil
  end

  def to_s
    (user ? (user.first_name.to_s + " " + user.last_name.to_s + " - ") : "") + (expense_category ? (expense_category.name.to_s + " - ") : "") + notes.to_s
  end

end
