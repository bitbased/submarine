class ProjectParticipant < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  default_scope { order('is_manager DESC') }

  acts_as_paranoid

  belongs_to :project
  belongs_to :contact
  belongs_to :user

  serialize :cache, JSON

  has_many :time_entries, through: :project

  attr_accessible :active, :cache, :cache_time, :is_manager, :contact_id, :user_id, :project_id, :archived_on, :audit_log, :change_time, :data, :deleted_at, :history, :locked_on, :notes, :permalog, :priority, :state, :status, :sync, :sync_time, :visible

  def serializable_hash(options={})
    options[:only] = [:id, :user_id, :contact_id, :project_id, :is_manager]
    #options[:include] = [:user, :contact]
    options[:methods] = [:total_hours]
    super(options)
  end
  def as_json(options={})
    super(options).reject { |k, v| v.nil? }
  end


  def fetch_cache(symbol)
    if !self.cache || !self.cache[symbol.to_s] || !self.cache_time || self.cache_time < 15.minutes.ago
      self.cache ||= {}
      self.cache["total_hours"] = user ? time_entries.where(:user_id => user_id).sum(:hours) : 0
      update_attributes(cache_time: DateTime.now, cache: self.cache)
    end
    self.cache[symbol.to_s]
  end

  def total_hours
    fetch_cache(:total_hours) 
  end



  #def to_json(options={})
  #  options[:only] ||= [:name, :code, :client_id, :client, :status, :active, :parent_id, :parent, :change_time, :description, :due_date, :open_date, :start_date, :close_date, :locked_on, :focus, :progress, :state, :tags, :visible]
  #  super(options)
  #end

end
