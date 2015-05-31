class InvoiceCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
    
  belongs_to :invoice_category

  has_many :harvest_invoice_categories, :foreign_key => 'invoice_category_id'
  #has_and_belongs_to_many :contacts

  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :name, :history, :locked_on, :notes, :password_digest, :permalog, :priority, :state, :sync, :sync_time, :visible, :use_as_service, :use_as_expense

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def to_s
    name
  end

end
