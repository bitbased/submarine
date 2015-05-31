class HarvestClient < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :client
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["Clients"]
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

    clients_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    Client.all.each do |client|
      if client.harvest_clients.length == 0
        harvest_client = HarvestClient.new

        tr = 0
        saved = false
        until saved
          begin            
            
            if crud[:can_create_remote] == true
              remote_client = Harvest::Client.new(:name => client.name, :details => client.details, :active => client.active)
              remote_client = hv.harvest.clients.create(remote_client)
              harvest_client.harvest_id = remote_client.id
              harvest_client.cache = remote_client.as_json
              client.harvest_clients << harvest_client
              client.save
            end

            log << "[NEW+] #{client.name}"
            saved = true

          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              tr += 1
              client.name = client.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end

      end
      clients_cache += client.harvest_clients
    end

    return log if mode == :create

    ### RETRIEVE REMOTE CLIENTS ###
    hv_clients = hv.get_clients

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    Client.only_deleted.each do |client|
      deleted_cache += client.harvest_clients
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_clients.each do |dd|
      clients_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[REMOTE DELETE] #{dd.name}" if crud[:can_delete_remote] == true
        log << "[REMOTE DELETE DISABLED] #{dd.name}" unless crud[:can_delete_remote] == true
        hv.harvest.clients.deactivate(dd) if crud[:can_deactivate_remote] and crud[:can_delete_remote] != true
        hv.harvest.clients.delete(dd) if crud[:can_delete_remote] == true
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    clients_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.client
        log << "[DELETED] #{c.client.name}"
        c.client.destroy if crud[:can_delete_local] == true
      end
    end

    hv_clients = hv.get_clients

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_clients.each do |remote_client|
      harvest_client = HarvestClient.with_deleted.find_or_initialize_by(harvest_id: remote_client.id)

      if harvest_client.cache == remote_client.as_json
        dir = :sync_diff
      elsif harvest_client.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["active", "name", "details"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from
        harvest_client.client = Client.find_or_initialize_by(name: remote_client.name) if harvest_client.client == nil
        remote_cache = remote_client.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          harvest_client.client[field] = remote_client[field]
          from = true
        end

        harvest_client.cache = remote_cache
        harvest_client.save
      end
      if dir == :sync_diff
        hv_up = remote_client.updated_at

        harvest_client.client = Client.find_or_initialize_by(name: remote_client.name) if harvest_client.client == nil
        remote_cache = remote_client.as_json

        sync_fields.each do |field|
          if remote_cache['client'][field] != harvest_client.cache['client'][field]
            changed_fields << "<--#{field}"
            harvest_client.client[field] = remote_client[field]
            from = true
            harvest_client.client.save
          end
        end
        harvest_client.cache = remote_cache
        harvest_client.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to


        sync_fields.each do |field|
          if remote_cache['client'][field] != harvest_client.client[field]
            changed_fields << "-->#{field}"
            
            if field == "active"
              if harvest_client.client[field]
                remote_client = hv.harvest.clients.activate(remote_client) if crud[:can_activate_remote] == true
              else
                begin
                  remote_client = hv.harvest.clients.deactivate(remote_client) if crud[:can_deactivate_remote] == true
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive client unless it has active projects"

                    #harvest_client.client.visible = false
                    #harvest_client.sync_errors << "Active Cannot archive an inactive client unless it has active projects"
                    harvest_client.client.active = true
                    harvest_client.client.save if crud[:can_update_local] == true

                  else
                    throw exception
                  end
                end

              end
            end

            remote_client.name = harvest_client.client[field] if field == "name"
            remote_client.details = harvest_client.client[field] if field == "details"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              remote_cache = hv.harvest.clients.update(remote_client).as_json if crud[:can_update_remote] == true
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                name = harvest_client.client.name
                name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_client.client.name = name
                harvest_client.client.save if crud[:can_update_local] == true
                remote_client.name = name
              else
                throw exception
              end
            end
          end


          harvest_client.cache = remote_cache
          harvest_client.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_client.client.name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end



  def self.find_local_client_by_harvest_id(harvest_id)
    begin
      return HarvestClient.find_by(harvest_id: harvest_id).client
    rescue
      return nil
    end
  end

end