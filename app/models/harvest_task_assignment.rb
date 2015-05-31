class HarvestTaskAssignment < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :project_task_category_assignment
  belongs_to :project
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :project_task_category_assignment_id

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["ProjectTaskCategoryAssignments"]
    Project.where(:update_associations => true).first(10).each do |project|      
      project.update_assignments = false
      log += syncronize_project_task_assignments(mode, project)
    end
    return log
  end

  def self.syncronize_project_task_assignments(mode = :only_from, project = nil)
    log = [">> ProjectTaskCategoryAssignment: #{project}"]
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

    task_assignments_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    ProjectTaskCategoryAssignment.where(project_id: project.id).each do |project_task_category_assignment|
      if project_task_category_assignment.harvest_task_assignments.length == 0
        harvest_task_assignment = nil

        tr = 0
        saved = false
        until saved
          begin

            if crud[:can_create_remote]
              remote_task_assignment = Harvest::TimeEntry.new()
              remote_task_assignment.project_id = project_task_category_assignment.project.harvest_id
              remote_task_assignment.task_id = project_task_category_assignment.task_category.harvest_id
              
              remote_task_assignment = hv.harvest.task_assignments.create(remote_task_assignment)

              harvest_task_assignment = HarvestTaskAssignment.with_deleted.find_or_initialize_by(harvest_id: remote_task_assignment.id)
              harvest_task_assignment.cache = remote_task_assignment.as_json
              harvest_task_assignment.harvest_id = remote_task_assignment.id
              harvest_task_assignment.project_task_category_assignment = project_task_category_assignment
              harvest_task_assignment.save
            end

            log << "[NEW+] #{project_task_category_assignment.task_category_name}"

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              throw exception # SOMETHING ODD HAPPENED
              tr += 1
              project_task_category_assignment.name = project_task_category_assignment.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end

      end
    end

    ProjectTaskCategoryAssignment.where(project_id: project.id).each do |project_task_category_assignment|
      task_assignments_cache += project_task_category_assignment.harvest_task_assignments
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_task_assignments = hv.get_task_assignments(project.harvest_id)

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    ProjectTaskCategoryAssignment.where(project_id: project.id).only_deleted.each do |project_task_category_assignment|
      deleted_cache += project_task_category_assignment.harvest_task_assignments
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_task_assignments.each do |dd|
      task_assignments_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[DELETED] #{find_local_task_category_by_harvest_id(dd.task_id).name rescue 'unknown'}"
        #hv.harvest.tasks.delete(dd)
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    task_assignments_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.project_task_category_assignment
        log << "[DELETED] #{c.project_task_category_assignment.task_category_name}"
        c.project_task_category_assignment.destroy
      end
    end

    hv_task_assignments = hv.get_task_assignments(project.harvest_id)

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_task_assignments.each do |remote_task_assignment|
      harvest_task_assignment = HarvestTaskAssignment.with_deleted.find_or_initialize_by(harvest_id: remote_task_assignment.id)
      
      if harvest_task_assignment.cache == remote_task_assignment.as_json
        dir = :sync_diff
      elsif harvest_task_assignment.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "project_id", "task_category_id"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from
        harvest_task_assignment.project_task_category_assignment = ProjectTaskCategoryAssignment.find_or_initialize_by(project_id: project.harvest_id, task_category_id: find_local_task_category_by_harvest_id(remote_task_assignment.task_category_id)) if harvest_task_assignment.project_task_category_assignment == nil
        remote_cache = remote_task_assignment.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          if field == "task_category_id"
            harvest_task_assignment.project_task_category_assignment.task_category = HarvestTaskCategory.find_local_task_category_by_harvest_id(remote_task_assignment[field.gsub("task_category_id","task_id")])
          elsif field == "project_id"
            harvest_task_assignment.project_task_category_assignment.project = HarvestProject.find_local_project_by_harvest_id(remote_task_assignment[field])
          elsif field == "active"
            harvest_task_assignment.project_task_category_assignment[field] = !remote_task_assignment["deactivated"]
          else
            harvest_task_assignment.project_task_category_assignment[field] = remote_task_assignment[field.gsub("task_category_id","task_id")]
          end
          from = true
        end
        
        harvest_task_assignment.cache = remote_cache
        harvest_task_assignment.save
      end
      if dir == :sync_diff
        hv_up = remote_task_assignment.updated_at

        harvest_task_assignment.project_task_category_assignment = ProjectTaskCategoryAssignment.find_or_initialize_by(project_id: project.harvest_id, task_category_id: find_local_task_category_by_harvest_id(remote_task_assignment.task_category_id)) if harvest_task_assignment.project_task_category_assignment == nil
        remote_cache = remote_task_assignment.as_json

        sync_fields.each do |field|

          if field == "active"
            if remote_cache['task_assignment']["deactivated"] != harvest_task_assignment.cache['task_assignment']["deactivated"]
              changed_fields << "<--#{field}"
              harvest_task_assignment.project_task_category_assignment[field] = !remote_task_assignment["deactivated"]
              from = true
              harvest_task_assignment.project_task_category_assignment.save
            end
          elsif field == "task_category_id"
            if remote_cache['task_assignment'][field.gsub("task_category_id","task_id")].to_s != harvest_task_assignment.cache['task_assignment'][field.gsub("task_category_id","task_id")].to_s
              changed_fields << "<--#{field}: #{remote_cache['task_assignment'][field.gsub("task_category_id","task_id")]}/#{harvest_task_assignment.cache['task_assignment'][field.gsub("task_category_id","task_id")]}"
              harvest_task_assignment.project_task_category_assignment.task_category = HarvestTaskCategory.find_local_task_category_by_harvest_id(remote_task_assignment[field.gsub("task_category_id","task_id")])
              from = true
              harvest_task_assignment.project_task_category_assignment.save if crud[:can_update_local]
            end
          elsif field == "project_id"
            if remote_cache['task_assignment'][field].to_s != harvest_task_assignment.cache['task_assignment'][field].to_s
              changed_fields << "<--#{field}"
              harvest_task_assignment.project_task_category_assignment.project = HarvestProject.find_local_project_by_harvest_id(remote_task_assignment[field])
              from = true
              harvest_time_entry.project_task_category_assignment.save if crud[:can_update_local]
            end
          elsif remote_cache['task_assignment'][field.gsub("task_category_id","task_id")] != harvest_task_assignment.cache['task_assignment'][field]
            changed_fields << "<--#{field}"
            harvest_task_assignment.project_task_category_assignment[field] = remote_task_assignment[field.gsub("task_category_id","task_id")]
            from = true
            harvest_task_assignment.project_task_category_assignment.save
          end
        end
        harvest_task_assignment.cache = remote_cache
        harvest_task_assignment.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to

        
        sync_fields.each do |field|


          if field == "active"

            if remote_cache['task_assignment']["deactivated"] != !harvest_task_assignment.project_task_category_assignment[field]
              changed_fields << "-->#{field}"

              log << "UPDATE #{remote_task_assignment.as_json}"
              if harvest_task_assignment.project_task_category_assignment[field]
                #remote_task_assignment = hv.harvest.task_assignments.activate(remote_task_assignment)
              else
                begin
                  #remote_task_assignment = hv.harvest.task_assignments.deactivate(remote_task_assignment)
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive project_task_category_assignment unless it has active projects"
                    
                    #harvest_task_assignment.project_task_category_assignment.visible = false
                    #harvest_task_assignment.sync_errors << "Active Cannot archive an inactive project_task_category_assignment unless it has active projects"
                    harvest_task_assignment.project_task_category_assignment.active = true
                    harvest_task_assignment.project_task_category_assignment.save

                  else
                    throw exception
                  end
                end
                
              end
              log << "UPDATE #{remote_task_assignment.as_json}"
              to = true
            end

          elsif field == "task_category_id"
            if remote_cache['task_assignment'][field.gsub("task_category_id","task_id")].to_s != harvest_task_assignment.project_task_category_assignment.task_category.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache['task_assignment'][field.gsub("task_category_id","task_id")].to_s}/#{harvest_task_assignment.project_task_category_assignment.task_category.harvest_id}"
              remote_task_assignment.task_id = harvest_task_assignment.project_task_category_assignment.task_category.harvest_id
              to = true
            end
          elsif field == "project_id"
            if remote_cache['task_assignment'][field].to_s != harvest_task_assignment.project_task_category_assignment.project.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache['task_assignment'][field].to_s}/#{harvest_task_assignment.project_task_category_assignment.project.harvest_id}"
              remote_task_assignment.project_id = harvest_task_assignment.project_task_category_assignment.project.harvest_id
              to = true
            end
          elsif remote_cache['task_assignment'][field] != harvest_task_assignment.project_task_category_assignment[field]
            changed_fields << "-->#{field}"

            remote_task_assignment.name = harvest_task_assignment.project_task_category_assignment[field] if field == "name"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              #remote_cache = hv.harvest.task_assignments.update(remote_task_assignment).as_json
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                name = harvest_task_assignment.project_task_category_assignment.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_task_assignment.project_task_category_assignment.name = name
                harvest_task_assignment.project_task_category_assignment.save
                remote_task_assignment.name = name
              else
                throw exception
              end
            end
          end


          harvest_task_assignment.cache = remote_cache
          harvest_task_assignment.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_task_assignment.project_task_category_assignment.task_category_name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

  def self.find_local_project_task_category_assignment_by_harvest_id(harvest_id)
    begin
      return HarvestTaskAssignment.find_by_harvest_id(harvest_id).project_task_category_assignment
    rescue
      return nil
    end
  end

  def self.find_local_task_category_by_harvest_id(harvest_id)
    begin
      return HarvestTaskCategory.find_by_harvest_id(harvest_id).task_category
    rescue
      return nil
    end
  end

end
