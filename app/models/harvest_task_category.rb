class HarvestTaskCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :task_category
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :task_category_id

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["TaskCategories"]
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

    task_categories_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    TaskCategory.all.each do |task_category|
      if task_category.harvest_task_categories.length == 0
        harvest_task_category = HarvestTaskCategory.new
        

        tr = 0
        saved = false
        until saved
          begin
            remote_task_category = Harvest::TaskCategory.new(:name => task_category.name, :is_default => task_category.is_default, :deactivated => !task_category.active)
            #remote_task_category = hv.harvest.tasks.create(remote_task_category)

            log << "[NEW+] #{task_category.name}"
            
            harvest_task_category.harvest_id = remote_task_category.id
            harvest_task_category.cache = remote_task_category.as_json
            harvest_task_category = task_category.harvest_task_categories
            harvest_task_category.save

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              tr += 1
              task_category.name = task_category.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end


      end
    end

    TaskCategory.all.each do |task_category|
      task_categories_cache += task_category.harvest_task_categories
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_task_categories = hv.get_task_categories

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    TaskCategory.only_deleted.each do |task_category|
      deleted_cache += task_category.harvest_task_categories
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_task_categories.each do |dd|
      task_categories_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[DELETED] #{dd.name}"
        #hv.harvest.tasks.delete(dd)
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    task_categories_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.task_category
        log << "[DELETED] #{c.task_category.name}"
        c.task_category.destroy
      end
    end

    hv_task_categories = hv.get_task_categories

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_task_categories.each do |remote_task_category|
      harvest_task_category = HarvestTaskCategory.with_deleted.find_or_initialize_by(harvest_id: remote_task_category.id)
      
      if harvest_task_category.cache == remote_task_category.as_json
        dir = :sync_diff
      elsif harvest_task_category.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "name", "is_default"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from
        harvest_task_category.task_category = TaskCategory.find_or_initialize_by(name: remote_task_category.name) if harvest_task_category.task_category == nil
        remote_cache = remote_task_category.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          if field == "active"
            harvest_task_category.task_category[field] = !remote_task_category["deactivated"]
          else
            harvest_task_category.task_category[field] = remote_task_category[field]
          end
          from = true
        end
        
        harvest_task_category.cache = remote_cache
        harvest_task_category.save
      end
      if dir == :sync_diff
        hv_up = remote_task_category.updated_at

        harvest_task_category.task_category = TaskCategory.find_or_initialize_by(name: remote_task_category.name) if harvest_task_category.task_category == nil
        remote_cache = remote_task_category.as_json

        sync_fields.each do |field|

          if field == "active"
            if remote_cache['task']["deactivated"] != harvest_task_category.cache['task']["deactivated"]
              changed_fields << "<--#{field}"
              harvest_task_category.task_category[field] = !remote_task_category["deactivated"]
              from = true
              harvest_task_category.task_category.save
            end
          elsif remote_cache['task'][field] != harvest_task_category.cache['task'][field]
            changed_fields << "<--#{field}"
            harvest_task_category.task_category[field] = remote_task_category[field]
            from = true
            harvest_task_category.task_category.save
          end
        end
        harvest_task_category.cache = remote_cache
        harvest_task_category.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to

        
        sync_fields.each do |field|


          if field == "active"

            if remote_cache['task']["deactivated"] != !harvest_task_category.task_category[field]
              changed_fields << "-->#{field}"

              log << "UPDATE #{remote_task_category.as_json}"
              if harvest_task_category.task_category[field]
                #remote_task_category = hv.harvest.task_categories.activate(remote_task_category)
              else
                begin
                  #remote_task_category = hv.harvest.task_categories.deactivate(remote_task_category)
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive task_category unless it has active projects"
                    
                    #harvest_task_category.task_category.visible = false
                    #harvest_task_category.sync_errors << "Active Cannot archive an inactive task_category unless it has active projects"
                    harvest_task_category.task_category.active = true
                    harvest_task_category.task_category.save

                  else
                    throw exception
                  end
                end

              end
              log << "UPDATE #{remote_task_category.as_json}"
              to = true
            end

          elsif remote_cache['task'][field] != harvest_task_category.task_category[field]
            changed_fields << "-->#{field}: #{remote_task_category.is_default}/#{harvest_task_category.task_category[field]}"

            remote_task_category.name = harvest_task_category.task_category[field] if field == "name"
            remote_task_category.is_default = harvest_task_category.task_category[field] if field == "is_default"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              #remote_cache = hv.harvest.tasks.update(remote_task_category).as_json
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                name = harvest_task_category.task_category.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_task_category.task_category.name = name
                harvest_task_category.task_category.save
                remote_task_category.name = name
              else
                throw exception
              end
            end
          end


          harvest_task_category.cache = remote_cache
          harvest_task_category.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_task_category.task_category.name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

  def self.find_local_task_category_by_harvest_id(harvest_id)
    begin
      return HarvestTaskCategory.find_by_harvest_id(harvest_id).task_category
    rescue
      return nil
    end
  end

end
