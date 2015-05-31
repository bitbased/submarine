require "timeout"

class Project < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :parent, class_name: "Project"
  belongs_to :client
  belongs_to :secondary_client, class_name: "Client"

  belongs_to :contact
  has_many :project_participants
  has_many :project_user_assignments
  has_many :project_task_category_assignments
  has_many :tasks

  serialize :cache, JSON
  serialize :update_associations_times, JSON

### BEGIN HARVEST

  has_many :time_entries
  has_many :expense_entries
  has_many :harvest_projects, :foreign_key => 'project_id'

##### END HARVEST

  attr_accessible :active, :cache, :cache_time, :archived_on, :secondary_client_id, :update_associations, :update_associations_time, :update_associations_times, :contact_id, :audit_log, :parent_id, :change_time, :close_date, :code, :data, :deleted_at, :description, :due_date, :focus, :history, :locked_on, :name, :notes, :open_date, :permalog, :priority, :progress, :start_date, :state, :status, :sync, :sync_time, :tags, :visible, :client_id

  after_create :syncronize
  def syncronize
    return unless Rails.env.production?
    return if ActivityLog.find_by(:activity => "syncronize", running: true)

    activity = ActivityLog.new(:activity => "syncronize", :message => "Creating ...")
    activity.running = true
    activity.change_time = DateTime.now
    activity.save

    sync_mode = :create

    log = []

    begin
      activity.message = "Creating ... \n" + log.join("\n")
      activity.save

      log += HarvestClient.syncronize(sync_mode)
      activity.message = "Creating ... \n" + log.join("\n")
      activity.save

      log += HarvestProject.syncronize(sync_mode)
      activity.message = "Creating ... \n" + log.join("\n")
      activity.save

    rescue Exception => e
      activity.message += "\n\n" + e.message + "\n" + e.backtrace.join("\n")
    end

    activity.running = false
    activity.dismiss_at = Time.now + 15.minutes
    activity.change_time = DateTime.now
    activity.save

    puts activity.message

  end

  def serializable_hash(options={})
    options[:only] ||= [:id, :project_participants, :client, :secondary_client, :name, :notes, :code, :client_id, :secondary_client_id, :status, :active, :parent_id, :due_date, :open_date]
    options[:include] ||= [:project_participants]
    options[:methods] ||= [:total_hours, :total_expenses, :harvest_id]
    super(options)
  end
  def as_json(options={})
    super(options).reject { |k, v| v.nil? }
  end

  def harvest_id
    harvest_projects.first.harvest_id rescue nil
  end



  def fetch_cache(symbol)
    if !self.cache || !self.cache[symbol.to_s] || !self.cache_time || self.cache_time < 15.minutes.ago
      self.cache ||= {}
      self.cache["total_hours"] = time_entries.sum(:hours).round(2)
      self.cache["total_expenses"] = expense_entries.sum(:total_cost).round(2).to_f
      update_attributes(cache_time: DateTime.now, cache: self.cache)
    end
    self.cache[symbol.to_s]
  end

  def total_hours
    fetch_cache(:total_hours) 
  end

  def total_expenses
    fetch_cache(:total_expenses) 
  end



  after_save ActivityWrapper.new(["name", "status", "code", "notes", "client_id", "secondary_client_id", "parent_id", "due_date", "start_date", "open_date", "close_date", "active", "progress"])
  #after_initialize ActivityWrapper.new

  def self.next_code(base = nil)
    max = 0
    Project.with_deleted.uniq.pluck(:code).each do |code|
      num = code.to_s.gsub(/[-\.\:\/\>].*/,"").gsub(/[A-Za-z]/,'').to_i rescue 0
      max = num if num > max
    end

    ActivityLog.where(:activity => "project.reserve_code").where("dismiss_at IS NULL OR dismiss_at > ?", DateTime.now).uniq.pluck(:data).each do |code|
      num = code.to_s.gsub(/[-\.\:\/\>].*/,"").gsub(/[A-Za-z]\.\s/,'').to_i rescue 0
      max = num if num > max
    end

    return max + 1
  end

  def to_s
    (client ? client.name + " " : "") + (code ? "[#{code}] " : "") + name
  end

  def to_label
    (code ? "[#{code}] " : "") + (client ? client.name + " - " : "") + name
  end

end
