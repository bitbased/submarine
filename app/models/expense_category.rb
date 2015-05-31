class ExpenseCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
    
  belongs_to :expense_category

  has_many :harvest_expense_categories, :foreign_key => 'expense_category_id'
  #has_and_belongs_to_many :contacts

  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :name, :history, :locked_on, :notes, :password_digest, :permalog, :priority, :state, :sync, :sync_time, :visible, :unit_name, :unit_price

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON



  def self.find_local_expense_category_by_harvest_id(harvest_id)
    begin
      return HarvestExpenseCategory.find_by(harvest_id: harvest_id).expense_category
    rescue
      return nil
    end
  end

  def harvest_id
    harvest_expense_categories.first.harvest_id rescue nil
  end

  def to_s
    name
  end

end
