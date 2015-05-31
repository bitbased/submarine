class HarvestProject < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :project
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :refresh_associations

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["Projects"]
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

      if mode == :create
        crud = {
          :can_activate_remote => false,
          :can_deactivate_remote => false,
          :can_create_remote => true,
          :can_update_remote => false,
          :can_delete_remote => false,

          :can_activate_local => false,
          :can_deactivate_local => false,
          :can_create_local => false,
          :can_update_local => false,
          :can_delete_local => false
        }
      end

      projects_cache = []
      ### FIND [NEW] LOCAL JOBS ###
      Project.all.each do |project|
        if project.harvest_projects.length == 0
          harvest_project = nil

          tr = 0
          saved = false
          until saved
            #break unless project.client
            begin
              if crud[:can_create_remote] == true
                remote_project = Harvest::Project.new(:code => project.code, :name => project.name, :client_id => project.client.harvest_clients.first.harvest_id, :notes => project.notes)
                remote_project = hv.harvest.projects.create(remote_project)

                harvest_project = HarvestProject.with_deleted.find_or_initialize_by(harvest_id: remote_project.id)
                harvest_project.cache = remote_project.as_json
                harvest_project.harvest_id = remote_project.id
                harvest_project.project = project
                harvest_project.save
                log << "[NEW+] #{project.name} [#{remote_project.id}]"
              else
                log << "[NEW+] #{project.name}"
              end

              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name can't be blank"
                project.name = "New Project~#{tr}"
              elsif exception.inspect.include? "Name has already been taken"
                tr += 1
                project.name = project.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
              else
                throw exception.inspect
              end
            end
          end

        end
      end

      return log if mode == :create

      Project.all.each do |project|
        projects_cache += project.harvest_projects
      end

      ### RETRIEVE REMOTE PROJECTS ###
      hv_projects = hv.get_projects

      ### FIND [DELETED] LOCAL PROJECTS ###
      deleted_cache = []
      Project.only_deleted.each do |project|
        deleted_cache += project.harvest_projects
      end
      deleted_cache.map! { |v| v.harvest_id }

      #log << deleted_cache.inspect

      hv_projects.each do |dd|
        projects_cache = projects_cache.reject { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
        if deleted_cache.include?(dd.id)
          log << "[REMOTE DELETE] #{dd.name}" if crud[:can_delete_remote] == true
          log << "[REMOTE DELETE DISABLED] #{dd.name}" unless crud[:can_delete_remote] == true
          hv.harvest.projects.deactivate(dd) if crud[:can_deactivate_remote] == true and crud[:can_delete_remote] != true
          hv.harvest.projects.delete(dd) if crud[:can_delete_remote] == true
        end
      end

      ### FIND [DELETED] REMOTE PROJECTS ###
      projects_cache.each do |c|
        c.destroy! # no longer keep a reference since we know harvest doesn't
        if c.project
          log << "[DELETED] #{c.project.name}"
          c.project.destroy if crud[:can_delete_local] == true
        end
      end

      hv_projects = hv.get_projects

      ### FIND [NEW] REMOTE PROJECTS ###
      ### SYNC [CHANGED] PROJECTS ###

      hv_projects.each do |remote_project|
        harvest_project = HarvestProject.with_deleted.find_or_initialize_by(harvest_id: remote_project.id)

        if harvest_project.cache == remote_project.as_json
          dir = :sync_diff
        elsif harvest_project.cache == nil
          create = true
          dir = :sync_from
        else
          dir = :sync_diff
        end

        sync_fields = ["active", "name", "notes", "client_id", "code"]
        changed_fields = []

        from = false
        to = false
        assoc = false


        if dir == :sync_from
          harvest_project.project = Project.find_or_initialize_by(name: remote_project.name, client_id: HarvestClient.find_local_client_by_harvest_id(remote_project.client_id).id) if harvest_project.project == nil
          remote_cache = remote_project.as_json

          sync_fields.each do |field|
            changed_fields << "<--#{field}"
            if field == "client_id"
              harvest_project.project.client = HarvestClient.find_local_client_by_harvest_id(remote_project[field])
            else
              harvest_project.project[field] = remote_project[field]
            end
            from = true
          end

          if !harvest_project.cache || remote_cache['project']['updated_at'] != harvest_project.cache['project']['updated_at']
            harvest_project.project.update_associations = true
            harvest_project.project.update_associations_time = DateTime.now
            harvest_project.project.save if crud[:can_update_local] == true
            #assoc = true
          end

          harvest_project.cache = remote_cache
          harvest_project.save
        end
        if dir == :sync_diff

          hv_up = remote_project.updated_at

          harvest_project.project = Project.find_or_initialize_by(name: remote_project.name, client_id: HarvestClient.find_local_client_by_harvest_id(remote_project.client_id).id) if harvest_project.project == nil
          remote_cache = remote_project.as_json

          if !harvest_project.cache || remote_cache['project']['updated_at'] != harvest_project.cache['project']['updated_at']
            harvest_project.refresh_associations = true
            harvest_project.project.update_associations = true
            harvest_project.project.update_associations_time = DateTime.now
            harvest_project.project.save if crud[:can_update_local] == true
            assoc = true
          end

          sync_fields.each do |field|
            if field == "client_id"
              if remote_cache['project'][field] != harvest_project.cache['project'][field]
                changed_fields << "<--#{field}"
                harvest_project.project.client = HarvestClient.find_local_client_by_harvest_id(remote_project[field])
                from = true
                harvest_project.project.save if crud[:can_update_local] == true
              end
            else
              if remote_cache['project'][field] != harvest_project.cache['project'][field]
                changed_fields << "<--#{field}"
                harvest_project.project[field] = remote_project[field]
                from = true
                harvest_project.project.save if crud[:can_update_local] == true
              end
            end
          end
          harvest_project.cache = remote_cache
          harvest_project.save

          if !from && changed_fields.count == 0
            dir = :sync_to
          end
        end
        if dir == :sync_to


          sync_fields.each do |field|
            if field == "client_id"
              if harvest_project.project.client && remote_cache['project'][field] != harvest_project.project.client.harvest_clients.first.harvest_id
                changed_fields << "-->#{field}"
                remote_project.client_id = harvest_project.project.client.harvest_clients.first.harvest_id
                to = true
              end
            else
              if remote_cache['project'][field] != harvest_project.project[field]
                changed_fields << "-->#{field}"

                if field == "active"
                  if harvest_project.project[field]
                    remote_project = hv.harvest.projects.activate(remote_project) if crud[:can_activate_remote] == true
                  else
                    remote_project = hv.harvest.projects.deactivate(remote_project) if crud[:can_deactivate_remote] == true
                  end
                end

                remote_project.code = harvest_project.project[field] if field == "code"
                remote_project.name = harvest_project.project[field] if field == "name"
                remote_project.notes = harvest_project.project[field] if field == "notes"
                to = true
              end
            end
          end

          if to


            tr = 0
            saved = false
            until saved
              begin
                remote_cache = hv.harvest.projects.update(remote_project).as_json if crud[:can_update_remote] == true
                saved = true
              rescue Harvest::BadRequest => exception

                if exception.inspect.include?("Name has already been taken") || exception.inspect.include?("Name can't be blank")
                  tr += 1
                  name = harvest_project.project.name
                  name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                  harvest_project.project.name = name
                  harvest_project.project.save if crud[:can_update_local] == true
                  remote_project.name = name
                else
                  throw exception
                end
              end
            end


            harvest_project.cache = remote_cache
            harvest_project.save
          end

        end
        if !from || !to
          changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
        end
        if to || from
          log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_project.project.client.name} - #{harvest_project.project.name}#{changed_fields.count > 0 ? " " + changed_fields.inspect : ""}"
          Rails.logger.debug log.last
        elsif assoc
          log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_project.project.name} <RESYNC>"
          Rails.logger.debug log.last
        end
      end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end


  def self.find_local_project_by_harvest_id(harvest_id)
    begin
      return HarvestProject.find_by_harvest_id(harvest_id).project
    rescue
      return nil
    end
  end

end
