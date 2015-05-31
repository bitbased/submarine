class HarvestUserAssignment < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :project_user_assignment
  belongs_to :project
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :project_user_assignment_id

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["ProjectUserAssignments"]
    Project.where(:update_associations => true).first(10).each do |project|      
      project.update_assignments = false
      log += syncronize_project_user_assignments(mode, project)
    end
    return log
  end

  def self.syncronize_project_user_assignments(mode = :only_from, project = nil)
    log = [">> ProjectUserAssignment: #{project}"]
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

    user_assignments_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    ProjectUserAssignment.where(project_id: project.id).each do |project_user_assignment|
      if project_user_assignment.harvest_user_assignments.length == 0
        harvest_user_assignment = nil

        tr = 0
        saved = false
        until saved
          begin

            if crud[:can_create_remote]
              remote_user_assignment = Harvest::UserAssignment.new()
              remote_user_assignment.project_id = project_user_assignment.project.harvest_id
              remote_user_assignment.user_id = project_user_assignment.user.harvest_id
              
              remote_user_assignment = hv.harvest.user_assignments.create(remote_user_assignment)

              harvest_user_assignment = HarvestUserAssignment.with_deleted.find_or_initialize_by(harvest_id: remote_user_assignment.id)
              harvest_user_assignment.cache = remote_user_assignment.as_json
              harvest_user_assignment.harvest_id = remote_user_assignment.id
              harvest_user_assignment.project_user_assignment = project_user_assignment
              harvest_user_assignment.save
            end

            log << "[NEW+] #{project_user_assignment.user}"

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              throw exception # SOMETHING ODD HAPPENED
              tr += 1
              project_user_assignment.name = project_user_assignment.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end

      end
    end

    ProjectUserAssignment.where(project_id: project.id).each do |project_user_assignment|
      user_assignments_cache += project_user_assignment.harvest_user_assignments
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_user_assignments = hv.get_user_assignments(project.harvest_id)

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    ProjectUserAssignment.where(project_id: project.id).only_deleted.each do |project_user_assignment|
      deleted_cache += project_user_assignment.harvest_user_assignments
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_user_assignments.each do |dd|
      user_assignments_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[DELETED] #{find_local_user_by_harvest_id(dd.user_id) rescue 'unknown'}"
        #hv.harvest.users.delete(dd)
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    user_assignments_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.project_user_assignment
        log << "[DELETED] Assignment: #{c.project_user_assignment.user}"
        c.project_user_assignment.destroy
      end
    end

    hv_user_assignments = hv.get_user_assignments(project.harvest_id)

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_user_assignments.each do |remote_user_assignment|
      harvest_user_assignment = HarvestUserAssignment.with_deleted.find_or_initialize_by(harvest_id: remote_user_assignment.id)
      
      if harvest_user_assignment.cache == remote_user_assignment.as_json
        dir = :sync_diff
      elsif harvest_user_assignment.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "project_id", "user_id"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from
        harvest_user_assignment.project_user_assignment = ProjectUserAssignment.find_or_initialize_by(project_id: project.harvest_id, user_id: find_local_user_by_harvest_id(remote_user_assignment.user_id)) if harvest_user_assignment.project_user_assignment == nil
        remote_cache = remote_user_assignment.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          if field == "user_id"
            harvest_user_assignment.project_user_assignment.user = HarvestUser.find_local_user_by_harvest_id(remote_user_assignment[field])
          elsif field == "project_id"
            harvest_user_assignment.project_user_assignment.project = HarvestProject.find_local_project_by_harvest_id(remote_user_assignment[field])
          elsif field == "active"
            harvest_user_assignment.project_user_assignment[field] = !remote_user_assignment["deactivated"]
          else
            harvest_user_assignment.project_user_assignment[field] = remote_user_assignment[field]
          end
          from = true
        end
        
        harvest_user_assignment.cache = remote_cache
        harvest_user_assignment.save
      end
      if dir == :sync_diff
        hv_up = remote_user_assignment.updated_at

        harvest_user_assignment.project_user_assignment = ProjectUserAssignment.find_or_initialize_by(project_id: project.harvest_id, user_id: find_local_user_by_harvest_id(remote_user_assignment.user_id)) if harvest_user_assignment.project_user_assignment == nil
        remote_cache = remote_user_assignment.as_json

        sync_fields.each do |field|

          if field == "active"
            if remote_cache['user_assignment']["deactivated"] != harvest_user_assignment.cache['user_assignment']["deactivated"]
              changed_fields << "<--#{field}"
              harvest_user_assignment.project_user_assignment[field] = !remote_user_assignment["deactivated"]
              from = true
              harvest_user_assignment.project_user_assignment.save
            end
          elsif field == "user_id"
            if remote_cache['user_assignment'][field].to_s != harvest_user_assignment.cache['user_assignment'][field].to_s
              changed_fields << "<--#{field}: #{remote_cache['user_assignment'][field]}/#{harvest_user_assignment.cache['user_assignment'][field]}"
              harvest_user_assignment.project_user_assignment.user = HarvestUser.find_local_user_by_harvest_id(remote_user_assignment[field])
              from = true
              harvest_user_assignment.project_user_assignment.save if crud[:can_update_local]
            end
          elsif field == "project_id"
            if remote_cache['user_assignment'][field].to_s != harvest_user_assignment.cache['user_assignment'][field].to_s
              changed_fields << "<--#{field}"
              harvest_user_assignment.project_user_assignment.project = HarvestProject.find_local_project_by_harvest_id(remote_user_assignment[field])
              from = true
              harvest_time_entry.project_user_assignment.save if crud[:can_update_local]
            end
          elsif remote_cache['user_assignment'][field] != harvest_user_assignment.cache['user_assignment'][field]
            changed_fields << "<--#{field}"
            harvest_user_assignment.project_user_assignment[field] = remote_user_assignment[field]
            from = true
            harvest_user_assignment.project_user_assignment.save
          end
        end
        harvest_user_assignment.cache = remote_cache
        harvest_user_assignment.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to

        
        sync_fields.each do |field|


          if field == "active"

            if remote_cache['user_assignment']["deactivated"] != !harvest_user_assignment.project_user_assignment[field]
              changed_fields << "-->#{field}"

              log << "UPDATE #{remote_user_assignment.as_json}"
              if harvest_user_assignment.project_user_assignment[field]
                #remote_user_assignment = hv.harvest.user_assignments.activate(remote_user_assignment)
              else
                begin
                  #remote_user_assignment = hv.harvest.user_assignments.deactivate(remote_user_assignment)
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive project_user_assignment unless it has active projects"
                    
                    #harvest_user_assignment.project_user_assignment.visible = false
                    #harvest_user_assignment.sync_errors << "Active Cannot archive an inactive project_user_assignment unless it has active projects"
                    harvest_user_assignment.project_user_assignment.active = true
                    harvest_user_assignment.project_user_assignment.save

                  else
                    throw exception
                  end
                end
                
              end
              log << "UPDATE #{remote_user_assignment.as_json}"
              to = true
            end

          elsif field == "user_id"
            if remote_cache['user_assignment'][field].to_s != harvest_user_assignment.project_user_assignment.user.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache['user_assignment'][field].to_s}/#{harvest_user_assignment.project_user_assignment.user.harvest_id}"
              remote_user_assignment.user_id = harvest_user_assignment.project_user_assignment.user.harvest_id
              to = true
            end
          elsif field == "project_id"
            if remote_cache['user_assignment'][field].to_s != harvest_user_assignment.project_user_assignment.project.harvest_id.to_s
              changed_fields << "-->#{field}: #{remote_cache['user_assignment'][field].to_s}/#{harvest_user_assignment.project_user_assignment.project.harvest_id}"
              remote_user_assignment.project_id = harvest_user_assignment.project_user_assignment.project.harvest_id
              to = true
            end
          elsif remote_cache['user_assignment'][field] != harvest_user_assignment.project_user_assignment[field]
            changed_fields << "-->#{field}"

            remote_user_assignment.name = harvest_user_assignment.project_user_assignment[field] if field == "name"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              #remote_cache = hv.harvest.user_assignments.update(remote_user_assignment).as_json
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                name = harvest_user_assignment.project_user_assignment.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_user_assignment.project_user_assignment.name = name
                harvest_user_assignment.project_user_assignment.save
                remote_user_assignment.name = name
              else
                throw exception
              end
            end
          end


          harvest_user_assignment.cache = remote_cache
          harvest_user_assignment.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_user_assignment.project_user_assignment.user}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

  def self.find_local_project_user_assignment_by_harvest_id(harvest_id)
    begin
      return HarvestUserAssignment.find_by_harvest_id(harvest_id).project_user_assignment
    rescue
      return nil
    end
  end

  def self.find_local_user_by_harvest_id(harvest_id)
    begin
      return HarvestUser.find_by_harvest_id(harvest_id).user
    rescue
      return nil
    end
  end

end
