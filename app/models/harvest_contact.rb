class HarvestContact < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid

  belongs_to :client
  belongs_to :contact
  belongs_to :parent, :class_name => ""
  has_many :tasks
  
  has_many :harvest_projects, :foreign_key => 'project_id'

  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON


  def self.syncronize(mode = :only_from)
    log = ["Contacts"]
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

    contacts_cache = []
    ### FIND [NEW] LOCAL JOBS ###
    Contact.all.each do |contact|
      if contact.harvest_contacts.length == 0
        harvest_contact = HarvestContact.new


        tr = 0
        saved = false
        until saved
          begin
            if crud[:can_create_local] == true
              remote_contact = Harvest::Contact.new(:first_name => contact.first_name, :last_name => contact.last_name, :client_id => contact.client.harvest_clients.first.harvest_id, :notes => contact.notes, :active => contact.active)
              remote_contact = hv.harvest.contacts.create(remote_contact)

              harvest_contact.harvest_id = remote_contact.id
              harvest_contact.cache = remote_contact.as_json
              contact.harvest_contacts << harvest_contact
              contact.save
            end

            log << "[NEW+] #{contact.first_name}"

            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              tr += 1
              contact.last_name = contact.last_name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end


      end
      contacts_cache += contact.harvest_contacts
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_contacts = hv.get_contacts

    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    Contact.only_deleted.each do |contact|
      deleted_cache += contact.harvest_contacts
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_contacts.each do |dd|
      contacts_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)

        log << "[REMOTE DELETE] #{dd.first_name} #{dd.last_name}" if crud[:can_delete_remote] == true
        log << "[REMOTE DELETE DISABLED] #{dd.first_name} #{dd.last_name}" unless crud[:can_delete_remote] == true
        #hv.harvest.contacts.deactivate(dd) if crud[:can_deactivate_remote] && !crud[:can_delete_remote]
        hv.harvest.contacts.delete(dd) if crud[:can_delete_remote] == true

      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    contacts_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.contact
        log << "[DELETED] #{c.contact.first_name} #{c.contact.last_name}"
        c.contact.destroy if crud[:can_delete_local] == true
      end
    end

    hv_contacts = hv.get_contacts

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_contacts.each do |remote_contact|
      harvest_contact = HarvestContact.with_deleted.find_or_initialize_by(harvest_id: remote_contact.id)

      if harvest_contact.cache == remote_contact.as_json
        dir = :sync_diff
      elsif harvest_contact.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end

      sync_fields = ["first_name", "last_name", "email", "title", "client_id"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from

        if HarvestClient.find_local_client_by_harvest_id(remote_contact.client_id) == nil
          log << "Remote contact not created, skipping record: #{remote_contact.inspect}"
          next
        end

        harvest_contact.contact = Contact.new(:first_name => remote_contact.first_name, :last_name => remote_contact.last_name, :client_id => HarvestClient.find_local_client_by_harvest_id(remote_contact.client_id).id) if harvest_contact.contact == nil
        remote_cache = remote_contact.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}"
          if field == "client_id"
            harvest_contact.contact.client = HarvestClient.find_local_client_by_harvest_id(remote_contact[field])
          else
            harvest_contact.contact[field] = remote_contact[field]
          end
          from = true
        end

        harvest_contact.cache = remote_cache
        harvest_contact.save
      end
      if dir == :sync_diff
        hv_up = remote_contact.updated_at

        harvest_contact.contact = Contact.new(:first_name => remote_contact.first_name, :last_name => remote_contact.last_name, :client_id =>  HarvestClient.find_local_client_by_harvest_id(remote_contact.client_id).id) if harvest_contact.contact == nil
        remote_cache = remote_contact.as_json

        sync_fields.each do |field|
          if field == "client_id"
            if remote_cache['contact'][field] != harvest_contact.cache['contact'][field]
              changed_fields << "<--#{field}"
              harvest_contact.contact.client = HarvestClient.find_local_client_by_harvest_id(remote_contact[field])
              from = true
              harvest_contact.contact.save
            end
          else
            if remote_cache['contact'][field] != harvest_contact.cache['contact'][field]
              changed_fields << "<--#{field}"
              harvest_contact.contact[field] = remote_contact[field]
              from = true
              harvest_contact.contact.save
            end
          end
        end
        harvest_contact.cache = remote_cache
        harvest_contact.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to


        sync_fields.each do |field|
          if field == "client_id"
            if remote_cache['contact'][field] != harvest_contact.contact.client.harvest_clients.first.harvest_id
              changed_fields << "-->#{field}"
              remote_contact.client_id = harvest_contact.contact.client.harvest_clients.first.harvest_id
              to = true
            end
          else
            if remote_cache['contact'][field] != harvest_contact.contact[field]
              changed_fields << "-->#{field}"

              if field == "active"
                if harvest_contact.contact[field]
                  remote_contact = hv.harvest.contacts.activate(remote_contact) if crud[:can_activate_remote] == true
                else
                  remote_contact = hv.harvest.contacts.deactivate(remote_contact) if crud[:can_deactivate_remote] == true
                end
              end

              remote_contact.first_name = harvest_contact.contact[field] if field == "first_name"
              remote_contact.last_name = harvest_contact.contact[field] if field == "last_name"
              remote_contact.email = harvest_contact.contact[field] if field == "email"
              remote_contact.title = harvest_contact.contact[field] if field == "title"
              to = true
            end
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              remote_cache = hv.harvest.contacts.update(remote_contact).as_json if crud[:can_update_remote] == true
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                last_name = harvest_contact.contact.last_name
                last_name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_contact.contact.last_name = last_name
                harvest_contact.contact.save if crud[:can_update_local] == true
                remote_contact.last_name = last_name
              else
                throw exception
              end
            end
          end


          harvest_contact.cache = remote_cache
          harvest_contact.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if to || from
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_contact.contact.first_name} #{harvest_contact.contact.last_name}#{changed_fields.count > 0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

end
