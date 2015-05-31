class Contact < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :client
  belongs_to :parent, :class_name => "Contact"

  has_many :harvest_contacts

  attr_accessible :active, :archived_on, :audit_log, :change_time, :company, :data, :deleted_at, :email, :fax_number, :first_name, :history, :last_name, :locked_on, :mobile_number, :notes, :office_number, :permalog, :priority, :shared, :state, :sync, :sync_time, :tags, :title, :visible, :client_id, :parent_id

  after_save ActivityWrapper.new(["active", "first_name", "last_name", "deleted_at", "parent_id", "client_id", "email", "office_number", "mobile_number", "fax_number", "shared", "notes", "details", "tags", "visible", "sync"])

  def serializable_hash(options={})
    options[:only] = [:id, :name, :email]
    super(options)
  end

  def to_s
    (title ? title + " ": "") + first_name + " " + last_name
  end

  def name
    first_name + " " + last_name
  end

end
