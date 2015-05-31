class HarvestExpenseCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :expense_category
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :expense_category_id, :unit_name, :unit_price

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["ExpenseCategories"]
    begin
    hv = HarvestHook.new

    crud = {
      :can_activate_remote => false,
      :can_deactivate_remote => false,
      :can_create_remote => false,
      :can_update_remote => false,
      :can_delete_remote => false,

      :can_activate_local => true,
      :can_deactivate_local => true,
      :can_create_local => true,
      :can_update_local => true,
      :can_delete_local => true
    }

    if mode == :sync
      crud = {
        :can_activate_remote => true,
        :can_deactivate_remote => true,
        :can_create_remote => true,
        :can_update_remote => true,
        :can_delete_remote => true,

        :can_activate_local => true,
        :can_deactivate_local => true,
        :can_create_local => true,
        :can_update_local => true,
        :can_delete_local => true
      }
    end

    expense_categories_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    ExpenseCategory.all.each do |expense_category|
      if expense_category.harvest_expense_categories.length == 0
        harvest_expense_category = HarvestExpenseCategory.new


        tr = 0
        saved = false
        until saved
          begin
            remote_expense_category = Harvest::ExpenseCategory.new(:name => expense_category.name, :deactivated => !expense_category.active)
            #remote_expense_category = hv.harvest.expenses.create(remote_expense_category)

            log << "[NEW+] #{expense_category.name}"
            
            harvest_expense_category.harvest_id = remote_expense_category.id
            harvest_expense_category.cache = remote_expense_category.as_json
            harvest_expense_category = expense_category.harvest_expense_categories
            harvest_expense_category.save

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              tr += 1
              expense_category.name = expense_category.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end


      end
    end

    ExpenseCategory.all.each do |expense_category|
      expense_categories_cache += expense_category.harvest_expense_categories
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_expense_categories = hv.get_expense_categories

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    ExpenseCategory.only_deleted.each do |expense_category|
      deleted_cache += expense_category.harvest_expense_categories
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_expense_categories.each do |dd|
      expense_categories_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[DELETED] #{dd.name}"
        #hv.harvest.expenses.delete(dd)
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    expense_categories_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.expense_category
        log << "[DELETED] #{c.expense_category.name}"
        c.expense_category.destroy
      end
    end

    hv_expense_categories = hv.get_expense_categories

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_expense_categories.each do |remote_expense_category|
      harvest_expense_category = HarvestExpenseCategory.with_deleted.find_or_initialize_by(harvest_id: remote_expense_category.id)
      
      if harvest_expense_category.cache == remote_expense_category.as_json
        dir = :sync_diff
      elsif harvest_expense_category.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "name", "unit_name", "unit_price"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from
        harvest_expense_category.expense_category = ExpenseCategory.find_or_initialize_by(name: remote_expense_category.name) if harvest_expense_category.expense_category == nil
        remote_cache = remote_expense_category.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          if field == "active"
            harvest_expense_category.expense_category[field] = !remote_expense_category["deactivated"]
          else
            harvest_expense_category.expense_category[field] = remote_expense_category[field]
          end
          from = true
        end
        
        harvest_expense_category.cache = remote_cache
        harvest_expense_category.save
      end
      if dir == :sync_diff
        hv_up = remote_expense_category.updated_at

        harvest_expense_category.expense_category = ExpenseCategory.find_or_initialize_by(name: remote_expense_category.name) if harvest_expense_category.expense_category == nil
        remote_cache = remote_expense_category.as_json

        sync_fields.each do |field|

          if field == "active"
            if remote_cache['expense_category']["deactivated"] != harvest_expense_category.cache['expense_category']["deactivated"]
              changed_fields << "<--#{field}"
              harvest_expense_category.expense_category[field] = !remote_expense_category["deactivated"]
              from = true
              harvest_expense_category.expense_category.save
            end
          elsif remote_cache['expense_category'][field] != harvest_expense_category.cache['expense_category'][field]
            changed_fields << "<--#{field}"
            harvest_expense_category.expense_category[field] = remote_expense_category[field]
            from = true
            harvest_expense_category.expense_category.save
          end
        end
        harvest_expense_category.cache = remote_cache
        harvest_expense_category.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to

        
        sync_fields.each do |field|


          if field == "active"

            if remote_cache['expense_category']["deactivated"] != !harvest_expense_category.expense_category[field]
              changed_fields << "-->#{field}"

              log << "UPDATE #{remote_expense_category.as_json}"
              if harvest_expense_category.expense_category[field]
                #remote_expense_category = hv.harvest.expense_categories.activate(remote_expense_category)
              else
                begin
                  #remote_expense_category = hv.harvest.expense_categories.deactivate(remote_expense_category)
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive expense_category unless it has active projects"
                    
                    #harvest_expense_category.expense_category.visible = false
                    #harvest_expense_category.sync_errors << "Active Cannot archive an inactive expense_category unless it has active projects"
                    harvest_expense_category.expense_category.active = true
                    harvest_expense_category.expense_category.save

                  else
                    throw exception
                  end
                end
                
              end
              log << "UPDATE #{remote_expense_category.as_json}"
              to = true
            end

          elsif remote_cache['expense_category'][field] != harvest_expense_category.expense_category[field]
            changed_fields << "-->#{field}"

            remote_expense_category.name = harvest_expense_category.expense_category[field] if field == "name"
            remote_expense_category.unit_name = harvest_expense_category.expense_category[field] if field == "unit_name"
            remote_expense_category.unit_price = harvest_expense_category.expense_category[field] if field == "unit_price"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              #remote_cache = hv.harvest.expense_categories.update(remote_expense_category).as_json
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                name = harvest_expense_category.expense_category.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_expense_category.expense_category.name = name
                harvest_expense_category.expense_category.save
                remote_expense_category.name = name
              else
                throw exception
              end
            end
          end


          harvest_expense_category.cache = remote_cache
          harvest_expense_category.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_expense_category.expense_category.name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

  def self.find_local_expense_category_by_harvest_id(harvest_id)
    begin
      return HarvestExpenseCategory.find_by_harvest_id(harvest_id).expense_category
    rescue
      return nil
    end
  end

end
