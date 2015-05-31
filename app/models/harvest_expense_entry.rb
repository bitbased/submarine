class HarvestExpenseEntry < ActiveRecord::Base
  extend SyncModel
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :expense_entry
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  syncs_with :harvest_expense_entry, {"id" => "id"}
  syncs_with :harvest_expense_entry, {"activated" => "deactiveted"}, mapping: :inverse
  syncs_with :harvest_expense_entry, {"name" => "name"}

  def self.syncronize(mode = :only_from, from_date = 7.days.ago, to_date = 1.month.from_now)
    log = ["ExpenseEntries"]
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

    crud[:can_deactivate_remote] = false
    crud[:can_activate_remote] = false

    expense_entries_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    ExpenseEntry.all.each do |expense_entry|
      if expense_entry.harvest_expense_entries.length == 0
        harvest_expense_entry = nil

        tr = 0
        saved = false
        until saved
          begin

            if crud[:can_create_remote]

              remote_expense_entry = Harvest::Expense.new(:notes => expense_entry.notes)#, :is_closed => !expense_entry.active)
              remote_expense_entry.project_id = expense_entry.project.harvest_id
              remote_expense_entry.user_id = expense_entry.user.harvest_id
              remote_expense_entry.expense_category_id = expense_entry.expense_category.harvest_id
              remote_expense_entry.spent_at = expense_entry.date.to_date
              remote_expense_entry.total_cost = expense_entry.total_cost
              remote_expense_entry.units = expense_entry.units
              
              remote_expense_entry = hv.harvest.expenses.create(remote_expense_entry, expense_entry.user.harvest_id)
              harvest_expense_entry = HarvestExpenseEntry.with_deleted.find_or_initialize_by(harvest_id: remote_expense_entry.id)
              harvest_expense_entry.cache = remote_expense_entry.as_json["expense"]
              harvest_expense_entry.harvest_id = remote_expense_entry.id
              harvest_expense_entry.expense_entry = expense_entry
              harvest_expense_entry.save
            end

            log << "[NEW+] #{expense_entry.notes}"

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              throw exception # SOMETHING ODD HAPPENED
              tr += 1
              expense_entry.name = expense_entry.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end

      end
    end

    ExpenseEntry.all.each do |expense_entry|
      expense_entries_cache += expense_entry.harvest_expense_entries
    end

    ### RETRIEVE REMOTE TIME ENTRIES ###
    hv_expense_entries = hv.get_expense_entries(from_date, to_date)

    ### FIND [DELETED] LOCAL TIME ENTRIES ###
    deleted_cache = []
    ExpenseEntry.only_deleted.each do |expense_entry|
      deleted_cache += expense_entry.harvest_expense_entries if expense_entry.date > from_date && expense_entry.date < to_date
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_expense_entries.each do |dd|
      expense_entries_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[REMOTE DELETE] #{dd.notes}" if crud[:can_delete_remote]
        log << "[REMOTE DELETE DISABLED] #{dd.notes}" unless crud[:can_delete_remote]
        hv.harvest.expenses.delete(dd.id, dd.user_id) if crud[:can_delete_remote]
      end
    end

    ### FIND [DELETED] REMOTE TIME_ENTRIES ###
    expense_entries_cache.each do |c|
      next if c.expense_entry and !(c.expense_entry.date > from_date and c.expense_entry.date < to_date)
      c.destroy # no longer keep a reference since we know harvest doesn't
      if c.expense_entry
        log << "[DELETED] #{c.expense_entry.notes}"
        c.expense_entry.destroy if crud[:can_delete_local]
      end
    end

    hv_expense_entries = hv.get_expense_entries(from_date, to_date)

    ### FIND [NEW] REMOTE TIME_ENTRIES ###
    ### SYNC [CHANGED] TIME_ENTRIES ###
    hv_expense_entries.each do |remote_expense_entry|
      harvest_expense_entry = HarvestExpenseEntry.with_deleted.find_or_initialize_by(harvest_id: remote_expense_entry.id)

      #puts remote_expense_entry.to_json

      if harvest_expense_entry.deleted?
        harvest_expense_entry.deleted_at = nil
        harvest_expense_entry.cache = nil
        create = true
        dir = :sync_from
      elsif harvest_expense_entry.cache == (remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)
        dir = :sync_diff
      elsif harvest_expense_entry.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "notes", "user_id", "expense_category_id", "project_id", "date", "units", "total_cost", "billed"]
      #sync_fields = ["active", "notes", "project_id"]
      changed_fields = []

      from = false
      to = false
      reset = false

      if dir == :sync_from
        harvest_expense_entry.expense_entry = ExpenseEntry.new(:notes => remote_expense_entry.notes) if harvest_expense_entry.expense_entry == nil
        remote_cache = (remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)

        sync_fields.each do |field|
          if field == "expense_category_id"
            harvest_expense_entry.expense_entry.expense_category = HarvestExpenseCategory.find_local_expense_category_by_harvest_id(remote_expense_entry[field])
          elsif field == "user_id"
            harvest_expense_entry.expense_entry.user = HarvestUser.find_local_user_by_harvest_id(remote_expense_entry[field])
          elsif field == "project_id"
            harvest_expense_entry.expense_entry.project = HarvestProject.find_local_project_by_harvest_id(remote_expense_entry[field])
          elsif field == "active"
            harvest_expense_entry.expense_entry[field] = !remote_expense_entry["is_closed"]
          else
            harvest_expense_entry.expense_entry[field] = remote_expense_entry[field.gsub("date","spent_at").gsub("billed","is_billed")]
          end

          changed_fields << "<--#{field}: #{harvest_expense_entry.expense_entry[field]}"
          from = true
        end

        harvest_expense_entry.cache ||= {}
        harvest_expense_entry.cache.merge!(remote_cache)
        harvest_expense_entry.save
      end
      if dir == :sync_diff
        hv_up = remote_expense_entry.updated_at

        harvest_expense_entry.expense_entry = ExpenseEntry.new(:notes => remote_expense_entry.notes) if harvest_expense_entry.expense_entry == nil
        remote_cache = (remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)

        sync_fields.each do |field|

          if field == "expense_category_id"
            if remote_cache[field].to_s != harvest_expense_entry.cache[field].to_s
              changed_fields << "<--#{field}: #{remote_cache[field]}/#{harvest_expense_entry.cache[field]}"
              harvest_expense_entry.expense_entry.expense_category = HarvestExpenseCategory.find_local_expense_category_by_harvest_id(remote_expense_entry[field])
              from = true
              harvest_expense_entry.expense_entry.save if crud[:can_update_local]
            end
          elsif field == "user_id"
            if remote_cache[field].to_s != harvest_expense_entry.cache[field].to_s
              changed_fields << "<--#{field}"
              harvest_expense_entry.expense_entry.user = HarvestUser.find_local_user_by_harvest_id(remote_expense_entry[field])
              from = true
              harvest_expense_entry.expense_entry.save if crud[:can_update_local]
            end
          elsif field == "project_id"
            if remote_cache[field].to_s != harvest_expense_entry.cache[field].to_s
              changed_fields << "<--#{field}"
              harvest_expense_entry.expense_entry.project = HarvestProject.find_local_project_by_harvest_id(remote_expense_entry[field])
              from = true
              harvest_expense_entry.expense_entry.save if crud[:can_update_local]
            end
          elsif field == "active"
            if (!remote_cache["is_closed"]).to_s != (!harvest_expense_entry.cache["is_closed"]).to_s
              changed_fields << "<--#{field}:? #{!remote_cache["is_closed"]}/#{!harvest_expense_entry.cache["is_closed"]}"
              harvest_expense_entry.expense_entry[field] = !remote_expense_entry["is_closed"]
              from = true
              harvest_expense_entry.expense_entry.save if crud[:can_update_local]
            end
          elsif remote_cache[field.gsub("date","spent_at").gsub("billed","is_billed")].to_s != harvest_expense_entry.cache[field.gsub("date","spent_at").gsub("billed","is_billed")].to_s
            #puts remote_cache.to_json
            #puts harvest_expense_entry.cache.to_json
            changed_fields << "<--#{field}: #{remote_cache[field.gsub("date","spent_at").gsub("billed","is_billed")]}/#{harvest_expense_entry.cache[field.gsub("date","spent_at").gsub("billed","is_billed")]}"
            harvest_expense_entry.expense_entry[field] = remote_expense_entry[field.gsub("date","spent_at").gsub("billed","is_billed")]
            from = true
            harvest_expense_entry.expense_entry.save if crud[:can_update_local]
          end
        end

        harvest_expense_entry.cache ||= {}
        harvest_expense_entry.cache.merge!(remote_cache)
        harvest_expense_entry.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to

        sync_fields.each do |field|

          if field == "date"
            if remote_expense_entry.spent_at.to_date != harvest_expense_entry.expense_entry.date.to_date
              changed_fields << "-->#{field}: #{remote_expense_entry.spent_at.to_date}/#{harvest_expense_entry.expense_entry.date.to_date}"
              remote_expense_entry.spent_at = harvest_expense_entry.expense_entry.date.to_date
              to = true
            end
          elsif field == "units"
            if (remote_cache[field].to_f - harvest_expense_entry.expense_entry.units.to_f).abs > 0.001
              changed_fields << "-->#{field}"
              remote_expense_entry.units = harvest_expense_entry.expense_entry[field]
              to = true
            end
          elsif field == "total_cost"
            if (remote_cache[field].to_f - harvest_expense_entry.expense_entry.total_cost.to_f).abs > 0.001
              changed_fields << "-->#{field}"
              remote_expense_entry.total_cost = harvest_expense_entry.expense_entry[field]
              to = true
            end
          elsif field == "expense_category_id"
            if remote_cache[field].to_s != harvest_expense_entry.expense_entry.expense_category.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache[field].to_s}/#{harvest_expense_entry.expense_entry.expense_category.harvest_id}"
              remote_expense_entry.expense_category_id = harvest_expense_entry.expense_entry.expense_category.harvest_id
              to = true
            end
          elsif field == "user_id"
            if harvest_expense_entry.expense_entry.user && remote_cache[field].to_s != harvest_expense_entry.expense_entry.user.harvest_id.to_s
              log << remote_cache
              log << field
              log << remote_cache[field]

              changed_fields << "-->#{field}:? #{remote_cache[field]}/#{harvest_expense_entry.expense_entry.user.harvest_id}"
              reset = true
              #remote_expense_entry.user_id = harvest_expense_entry.expense_entry.user.harvest_id
              to = true
            end
          elsif field == "project_id"
            if remote_cache[field].to_s != harvest_expense_entry.expense_entry.project.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache[field]}/#{harvest_expense_entry.expense_entry.project.harvest_id}"
              remote_expense_entry.project_id = harvest_expense_entry.expense_entry.project.harvest_id
              to = true
            end
          elsif field == "active"

            if (!remote_cache["is_closed"]).to_s != (harvest_expense_entry.expense_entry[field]).to_s
              changed_fields << "-->#{field}: #{!remote_cache["is_closed"]}/#{harvest_expense_entry.expense_entry[field]}"

              log << "UPDATE #{(remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)}"
              if harvest_expense_entry.expense_entry[field]
                remote_expense_entry = hv.harvest.expenses.activate(remote_expense_entry, remote_expense_entry["user_id"]) if crud[:can_activate_remote]
              else
                begin
                  remote_expense_entry = hv.harvest.expenses.deactivate(remote_expense_entry, remote_expense_entry["user_id"]) if crud[:can_deactivate_remote]
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive expense_entry unless it has active projects"
                    
                    #harvest_expense_entry.expense_entry.visible = false
                    #harvest_expense_entry.sync_errors << "Active Cannot archive an inactive expense_entry unless it has active projects"
                    harvest_expense_entry.expense_entry.active = true
                    harvest_expense_entry.expense_entry.save

                  else
                    throw exception
                  end
                end

              end
              log << "UPDATE #{(remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)}"
              to = true
            end

          elsif remote_cache[field.gsub("billed","is_billed")].to_s != harvest_expense_entry.expense_entry[field].to_s
            changed_fields << "-->#{field}: #{remote_cache[field.gsub("billed","is_billed")]}/#{harvest_expense_entry.expense_entry[field]}"

            remote_expense_entry.notes = harvest_expense_entry.expense_entry[field] if field == "notes"
            remote_expense_entry.is_billed = harvest_expense_entry.expense_entry[field] if field == "billed"
            to = true
          end
        end

        if to

          tr = 0
          saved = false
          until saved
            begin
              remote_cache = hv.harvest.expenses.update(remote_expense_entry, remote_expense_entry["user_id"]).as_json if crud[:can_update_remote]
              remote_cache = (remote_cache["expense"] || remote_cache)
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                throw exception # SOMETHING ODD HAPPENED
                tr += 1
                name = harvest_expense_entry.expense_entry.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_expense_entry.expense_entry.name = name
                harvest_expense_entry.expense_entry.save if crud[:can_update_local]
                remote_expense_entry.name = name
              else
                throw exception
              end
            end
          end

          harvest_expense_entry.cache ||= {}
          harvest_expense_entry.cache.merge!(remote_cache)
          harvest_expense_entry.save
        end

      end

      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_expense_entry.expense_entry.notes}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end

      if reset && crud[:can_delete_remote] && crud[:can_create_remote]
        harvest_expense_entry.delete if crud[:can_delete_remote]
        hv.harvest.expenses.delete(remote_expense_entry, remote_expense_entry.user_id) if crud[:can_delete_remote]
        harvest_expense_entry.delete! if crud[:can_delete_remote]

        [harvest_expense_entry.expense_entry].each do |expense_entry|
            harvest_expense_entry = nil

            tr = 0
            saved = false
            until saved
              begin

                if crud[:can_create_remote]

                  remote_expense_entry = Harvest::Expense.new(:notes => expense_entry.notes)#, :is_closed => !expense_entry.active)
                  remote_expense_entry.project_id = expense_entry.project.harvest_id
                  remote_expense_entry.user_id = expense_entry.user.harvest_id
                  remote_expense_entry.expense_category_id = expense_entry.expense_category.harvest_id
                  remote_expense_entry.spent_at = expense_entry.date.to_date
                  remote_expense_entry.total_cost = expense_entry.total_cost
                  remote_expense_entry.units = expense_entry.units
  
                  log << remote_expense_entry.to_json

                  remote_expense_entry = hv.harvest.expenses.create(remote_expense_entry, expense_entry.user.harvest_id)
                  harvest_expense_entry = HarvestExpenseEntry.with_deleted.find_or_initialize_by(harvest_id: remote_expense_entry.id)
                  harvest_expense_entry.cache = (remote_expense_entry.as_json["expense"] || remote_expense_entry.as_json)
                  harvest_expense_entry.harvest_id = remote_expense_entry.id
                  harvest_expense_entry.expense_entry = expense_entry
                  harvest_expense_entry.save
                end

                log << "[RESET+] #{expense_entry.notes}"

                saved = true
              rescue Harvest::BadRequest => exception
                if exception.inspect.include? "Name has already been taken"
                  throw exception # SOMETHING ODD HAPPENED
                  tr += 1
                  expense_entry.name = expense_entry.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                else
                  throw exception
                end
              end
            end

        end

      end

    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

end
