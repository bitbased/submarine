class HarvestTimeEntry < ActiveRecord::Base
  extend SyncModel
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :time_entry
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  syncs_with :harvest_time_entry, {"id" => "id"}
  syncs_with :harvest_time_entry, {"activated" => "deactiveted"}, mapping: :inverse
  syncs_with :harvest_time_entry, {"name" => "name"}

  def self.syncronize(mode = :only_from, from_date = 7.days.ago, to_date = 1.month.from_now)
    log = ["TimeEntries"]
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

    time_entries_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    TimeEntry.all.each do |time_entry|
      if time_entry.harvest_time_entries.length == 0
        harvest_time_entry = nil

        tr = 0
        saved = false
        until saved
          begin

            if crud[:can_create_remote]

              remote_time_entry = Harvest::TimeEntry.new(:notes => time_entry.notes)#, :is_closed => !time_entry.active)
              remote_time_entry.project_id = time_entry.project.harvest_id
              remote_time_entry.user_id = time_entry.user.harvest_id
              remote_time_entry.task_id = time_entry.task_category.harvest_id
              remote_time_entry.spent_at = time_entry.date.to_date
              remote_time_entry.hours = time_entry.hours
              
              #log << remote_time_entry.to_json
              
              remote_time_entry.hours = 0.05 if time_entry.hours < 0.01
              remote_time_entry = hv.harvest.time.create(remote_time_entry, time_entry.user.harvest_id)
              if time_entry.hours < 0.01
                remote_time_entry.hours = time_entry.hours
                hv.harvest.time.update(remote_time_entry, time_entry.user.harvest_id)
              end
              harvest_time_entry = HarvestTimeEntry.with_deleted.find_or_initialize_by(harvest_id: remote_time_entry.id)
              harvest_time_entry.cache = remote_time_entry.as_json
              harvest_time_entry.harvest_id = remote_time_entry.id
              harvest_time_entry.time_entry = time_entry
              harvest_time_entry.save
            end

            log << "[NEW+] #{time_entry.notes}"

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              throw exception # SOMETHING ODD HAPPENED
              tr += 1
              time_entry.name = time_entry.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end

      end
    end

    TimeEntry.all.each do |time_entry|
      time_entries_cache += time_entry.harvest_time_entries
    end

    ### RETRIEVE REMOTE TIME ENTRIES ###
    hv_time_entries = hv.get_time_entries(from_date, to_date)

    ### FIND [DELETED] LOCAL TIME ENTRIES ###
    deleted_cache = []
    TimeEntry.only_deleted.each do |time_entry|
      deleted_cache += time_entry.harvest_time_entries if time_entry.date > from_date && time_entry.date < to_date
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_time_entries.each do |dd|
      time_entries_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[REMOTE DELETE] #{dd.notes}" if crud[:can_delete_remote]
        log << "[REMOTE DELETE DISABLED] #{dd.notes}" unless crud[:can_delete_remote]
        hv.harvest.time.delete(dd, dd.user_id) if crud[:can_delete_remote]
      end
    end

    ### FIND [DELETED] REMOTE TIME_ENTRIES ###
    time_entries_cache.each do |c|
      next if c.time_entry and !(c.time_entry.date > from_date and c.time_entry.date < to_date)
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.time_entry
        log << "[DELETED] #{c.time_entry.notes}"
        c.time_entry.destroy if crud[:can_delete_local]
      end
    end

    hv_time_entries = hv.get_time_entries(from_date, to_date)

    ### FIND [NEW] REMOTE TIME_ENTRIES ###
    ### SYNC [CHANGED] TIME_ENTRIES ###
    hv_time_entries.each do |remote_time_entry|
      harvest_time_entry = HarvestTimeEntry.with_deleted.find_or_initialize_by(harvest_id: remote_time_entry.id)
      #puts remote_time_entry.to_json

      if harvest_time_entry.deleted?
        harvest_time_entry.deleted_at = nil
        harvest_time_entry.cache = nil
        create = true
        dir = :sync_from
      elsif harvest_time_entry.cache == remote_time_entry.as_json
        dir = :sync_diff
      elsif harvest_time_entry.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "notes", "user_id", "task_category_id", "project_id", "date", "billed", "hours", "timer_started_at"]
      #sync_fields = ["active", "notes", "project_id"]
      changed_fields = []

      from = false
      to = false
      reset = false

      if dir == :sync_from
        harvest_time_entry.time_entry = TimeEntry.new(:notes => remote_time_entry.notes) if harvest_time_entry.time_entry == nil
        remote_cache = remote_time_entry.as_json

        sync_fields.each do |field|
          if field == "task_category_id"
            harvest_time_entry.time_entry.task_category = HarvestTaskCategory.find_local_task_category_by_harvest_id(remote_time_entry[field.gsub("task_category_id","task_id")])
          elsif field == "user_id"
            harvest_time_entry.time_entry.user = HarvestUser.find_local_user_by_harvest_id(remote_time_entry[field])
          elsif field == "project_id"
            harvest_time_entry.time_entry.project = HarvestProject.find_local_project_by_harvest_id(remote_time_entry[field])
          elsif field == "active"
            harvest_time_entry.time_entry[field] = !remote_time_entry["is_closed"]
          elsif field == "hours"
            harvest_time_entry.time_entry.hours = remote_time_entry[field]
          else
            harvest_time_entry.time_entry[field] = remote_time_entry[field.gsub("date","spent_at").gsub("billed","is_billed")]
          end

          changed_fields << "<--#{field}: #{harvest_time_entry.time_entry[field]}"
          from = true
        end

        harvest_time_entry.cache ||= {}
        harvest_time_entry.cache.merge!(remote_cache)
        harvest_time_entry.save
      end
      if dir == :sync_diff
        hv_up = remote_time_entry.updated_at

        harvest_time_entry.time_entry = TimeEntry.new(:notes => remote_time_entry.notes) if harvest_time_entry.time_entry == nil
        remote_cache = remote_time_entry.as_json

        sync_fields.each do |field|

          if field == "hours"
            if remote_cache[field] != harvest_time_entry.cache[field]
              changed_fields << "<--#{field}"
              harvest_time_entry.time_entry.hours = remote_time_entry[field]
              from = true
              harvest_time_entry.time_entry.save if crud[:can_update_local]
            end
          elsif field == "task_category_id"
            if remote_cache[field.gsub("task_category_id","task_id")].to_s != harvest_time_entry.cache[field.gsub("task_category_id","task_id")].to_s
              changed_fields << "<--#{field}: #{remote_cache[field.gsub("task_category_id","task_id")]}/#{harvest_time_entry.cache[field.gsub("task_category_id","task_id")]}"
              harvest_time_entry.time_entry.task_category = HarvestTaskCategory.find_local_task_category_by_harvest_id(remote_time_entry[field.gsub("task_category_id","task_id")])
              from = true
              harvest_time_entry.time_entry.save if crud[:can_update_local]
            end
          elsif field == "user_id"
            if remote_cache[field] != harvest_time_entry.cache[field]
              changed_fields << "<--#{field}"
              harvest_time_entry.time_entry.user = HarvestUser.find_local_user_by_harvest_id(remote_time_entry[field])
              from = true
              harvest_time_entry.time_entry.save if crud[:can_update_local]
            end
          elsif field == "project_id"
            if remote_cache[field].to_s != harvest_time_entry.cache[field].to_s
              changed_fields << "<--#{field}"
              harvest_time_entry.time_entry.project = HarvestProject.find_local_project_by_harvest_id(remote_time_entry[field])
              from = true
              harvest_time_entry.time_entry.save if crud[:can_update_local]
            end
          elsif field == "active"
            if (!remote_cache["is_closed"]).to_s != (!harvest_time_entry.cache["is_closed"]).to_s
              changed_fields << "<--#{field}:? #{!remote_cache["is_closed"]}/#{!harvest_time_entry.cache["is_closed"]}"
              harvest_time_entry.time_entry[field] = !remote_time_entry["is_closed"]
              from = true
              harvest_time_entry.time_entry.save if crud[:can_update_local]
            end
          elsif remote_cache[field.gsub("date","spent_at").gsub("billed","is_billed")].to_s != harvest_time_entry.cache[field.gsub("date","spent_at").gsub("billed","is_billed")].to_s
            #puts remote_cache.to_json
            #puts harvest_time_entry.cache.to_json
            changed_fields << "<--#{field}: #{remote_cache[field.gsub("date","spent_at").gsub("billed","is_billed")]}/#{harvest_time_entry.cache[field.gsub("date","spent_at").gsub("billed","is_billed")]}"
            harvest_time_entry.time_entry[field] = remote_time_entry[field.gsub("date","spent_at").gsub("billed","is_billed")]
            from = true
            harvest_time_entry.time_entry.save if crud[:can_update_local]
          end
        end

        harvest_time_entry.cache ||= {}
        harvest_time_entry.cache.merge!(remote_cache)
        harvest_time_entry.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to


        sync_fields.each do |field|

          if field == "timer_started_at"
            ts = remote_time_entry.timer_started_at
            ts = nil if ts == ""
            ts = DateTime.parse(ts.to_s) if ts != nil
            if ts != nil && harvest_time_entry.time_entry.timer_started_at != nil && (ts.to_datetime - harvest_time_entry.time_entry.timer_started_at.to_datetime).abs > 0
              changed_fields << "-->#{field}"
              remote_time_entry.timer_started_at = harvest_time_entry.time_entry.timer_started_at
            elsif ts.nil? != harvest_time_entry.time_entry.timer_started_at.nil?
              changed_fields << "-->#{field}"
              remote_time_entry.timer_started_at = harvest_time_entry.time_entry.timer_started_at
            end
            #if ((ts == nil || harvest_time_entry.time_entry.timer_started_at == nil) && !(ts == nil && harvest_time_entry.time_entry.timer_started_at == nil)) ||
            #  (ts != nil && (ts - harvest_time_entry.time_entry.timer_started_at).abs != 0)
            #  changed_fields << "-->#{field}"
            #  remote_time_entry.timer_started_at = harvest_time_entry.time_entry.timer_started_at
            #  to = true
            #end
          elsif field == "date"
            if remote_time_entry.spent_at.to_date != harvest_time_entry.time_entry.date.to_date
              changed_fields << "-->#{field}: #{remote_time_entry.spent_at.to_date}/#{harvest_time_entry.time_entry.date.to_date}"
              remote_time_entry.spent_at = harvest_time_entry.time_entry.date.to_date
              to = true
            end
          elsif field == "hours"
            if (remote_cache[field].to_f - harvest_time_entry.time_entry.hours).abs > 0.005
              changed_fields << "-->#{field}: #{remote_cache[field].to_f}/#{harvest_time_entry.time_entry.hours}"
              remote_time_entry.hours = harvest_time_entry.time_entry[field]
              to = true
            end
          elsif field == "task_category_id"
            if remote_cache[field.gsub("task_category_id","task_id")].to_s != harvest_time_entry.time_entry.task_category.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache[field.gsub("task_category_id","task_id")].to_s}/#{harvest_time_entry.time_entry.task_category.harvest_id}"
              remote_time_entry.task_id = harvest_time_entry.time_entry.task_category.harvest_id
              to = true
            end
          elsif field == "user_id"
            if  harvest_time_entry.time_entry.user != nil && remote_cache[field].to_s != harvest_time_entry.time_entry.user.harvest_id.to_s
              reset = true
              changed_fields << "-->#{field}:? #{remote_cache[field].to_s}/#{harvest_time_entry.time_entry.user.harvest_id}"
              #remote_time_entry.user_id = harvest_time_entry.time_entry.user.harvest_id
              to = true
            end
          elsif field == "project_id"
            if remote_cache[field].to_s != harvest_time_entry.time_entry.project.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache[field].to_s}/#{harvest_time_entry.time_entry.project.harvest_id}"
              remote_time_entry.project_id = harvest_time_entry.time_entry.project.harvest_id
              to = true
            end
          elsif field == "active"

            if (!remote_cache["is_closed"]).to_s != (harvest_time_entry.time_entry[field]).to_s
              changed_fields << "-->#{field}: #{!remote_cache["is_closed"]}/#{harvest_time_entry.time_entry[field]}"

              log << "UPDATE #{remote_time_entry.as_json}"
              if harvest_time_entry.time_entry[field]
                remote_time_entry = hv.harvest.time.activate(remote_time_entry, remote_time_entry["user_id"]) if crud[:can_activate_remote]
              else
                begin
                  remote_time_entry = hv.harvest.time.deactivate(remote_time_entry, remote_time_entry["user_id"]) if crud[:can_deactivate_remote]
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive time_entry unless it has active projects"
                    
                    #harvest_time_entry.time_entry.visible = false
                    #harvest_time_entry.sync_errors << "Active Cannot archive an inactive time_entry unless it has active projects"
                    harvest_time_entry.time_entry.active = true
                    harvest_time_entry.time_entry.save

                  else
                    throw exception
                  end
                end

              end
              log << "UPDATE #{remote_time_entry.as_json}"
              to = true
            end

          elsif remote_cache[field.gsub("billed","is_billed")].to_s != harvest_time_entry.time_entry[field].to_s
            changed_fields << "-->#{field}: #{remote_cache[field.gsub("billed","is_billed")]}/#{harvest_time_entry.time_entry[field]}"

            remote_time_entry.notes = harvest_time_entry.time_entry[field] if field == "notes"
            remote_time_entry.is_billed = harvest_time_entry.time_entry[field] if field == "billed"
            to = true
          end
        end

        if to

          tr = 0
          saved = false
          until saved
            begin
              remote_cache = hv.harvest.time.update(remote_time_entry, remote_time_entry["user_id"]).as_json if crud[:can_update_remote]
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                throw exception # SOMETHING ODD HAPPENED
                tr += 1
                name = harvest_time_entry.time_entry.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_time_entry.time_entry.name = name
                harvest_time_entry.time_entry.save if crud[:can_update_local]
                remote_time_entry.name = name
              else
                throw exception
              end
            end
          end

          harvest_time_entry.cache ||= {}
          harvest_time_entry.cache.merge!(remote_cache)
          harvest_time_entry.save
        end

      end

      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_time_entry.time_entry.notes}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end

      if reset && crud[:can_delete_remote] && crud[:can_create_remote]
        harvest_time_entry.delete if crud[:can_delete_remote]
        hv.harvest.time.delete(remote_time_entry, remote_time_entry["user_id"]) if crud[:can_delete_remote]
        harvest_time_entry.delete! if crud[:can_delete_remote]

        [harvest_time_entry.time_entry].each do |time_entry|
            harvest_time_entry = nil

            tr = 0
            saved = false
            until saved
              begin

                if crud[:can_create_remote]

                  remote_time_entry = Harvest::TimeEntry.new(:notes => time_entry.notes)#, :is_closed => !time_entry.active)
                  remote_time_entry.project_id = time_entry.project.harvest_id
                  remote_time_entry.user_id = time_entry.user.harvest_id
                  remote_time_entry.task_id = time_entry.task_category.harvest_id
                  remote_time_entry.spent_at = time_entry.date.to_date
                  remote_time_entry.hours = time_entry.hours
  
                  log << remote_time_entry.to_json

                  remote_time_entry.hours = 0.05 if time_entry.hours < 0.01
                  remote_time_entry = hv.harvest.time.create(remote_time_entry, time_entry.user.harvest_id)
                  if time_entry.hours < 0.01
                    remote_time_entry.hours = time_entry.hours
                    hv.harvest.time.update(remote_time_entry, time_entry.user.harvest_id)
                  end  
                  harvest_time_entry = HarvestTimeEntry.with_deleted.find_or_initialize_by(harvest_id: remote_time_entry.id)
                  harvest_time_entry.cache = remote_time_entry.as_json
                  harvest_time_entry.harvest_id = remote_time_entry.id
                  harvest_time_entry.time_entry = time_entry
                  harvest_time_entry.save
                end

                log << "[RESET+] #{time_entry.notes}"

                saved = true
              rescue Harvest::BadRequest => exception
                if exception.inspect.include? "Name has already been taken"
                  throw exception # SOMETHING ODD HAPPENED
                  tr += 1
                  time_entry.name = time_entry.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
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
