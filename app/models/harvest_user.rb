class HarvestUser < ActiveRecord::Base
  default_scope -> { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  #acts_as_paranoid

  belongs_to :user
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["Users"]
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
      :can_delete_local => false
    }

    if mode == :sync
      crud = {
        :can_activate_remote => true,
        :can_deactivate_remote => true,
        :can_create_remote => false,
        :can_update_remote => true,
        :can_delete_remote => false,

        :can_activate_local => true,
        :can_deactivate_local => true,
        :can_create_local => true,
        :can_update_local => true,
        :can_delete_local => false
      }
    end

    users_cache = []
    ### FIND [NEW] LOCAL CLIENTS ###
    User.all.each do |user|
      if user.harvest_users.length == 0
        harvest_user = HarvestUser.new


        tr = 0
        saved = false
        until saved
          begin
            remote_user = Harvest::User.new(:first_name => user.first_name, :last_name => user.last_name, :email => user.email, :is_active => user.active, :timezone => "Central Time (US & Canada)", :is_admin => false, :is_contractor => false)
            #remote_user = hv.harvest.users.create(remote_user)
            saved = true
          rescue Harvest::BadRequest => exception
            if exception.inspect.include? "Name has already been taken"
              tr += 1
              user.last_name = user.last_name.gsub(/~[0-9]+$/,"") + "~#{tr}"
            else
              throw exception
            end
          end
        end


        log << "[NEW+] #{user.first_name} #{user.last_name}"

        harvest_user.harvest_id = remote_user.id
        harvest_user.cache = remote_user.as_json
        user.harvest_users << harvest_user
        user.save
      end
      users_cache += user.harvest_users
    end

    ### RETRIEVE REMOTE CLIENTS ###
    hv_users = hv.get_users
    ### FIND [DELETED] LOCAL CLIENTS ###
    deleted_cache = []
    User.only_deleted.each do |user|
      deleted_cache += user.harvest_users
    end
    deleted_cache.map! { |v| v.harvest_id }

    #log << deleted_cache.inspect

    hv_users.each do |dd|
      users_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
      if deleted_cache.include?(dd.id)
        log << "[DELETED] #{dd.first_name} #{dd.last_name}"
        #hv.harvest.users.delete(dd) # NEVER DO THIS?
      end
    end

    ### FIND [DELETED] REMOTE CLIENTS ###
    users_cache.each do |c|
      c.destroy! # no longer keep a reference since we know harvest doesn't
      if c.user
        log << "[DELETED] #{c.user.first_name} #{c.user.last_name}"
        c.user.destroy
      end
    end

    hv_users = hv.get_users

    ### FIND [NEW] REMOTE CLIENTS ###
    ### SYNC [CHANGED] CLIENTS ###
    hv_users.each do |remote_user|
      harvest_user = HarvestUser.find_or_initialize_by(harvest_id: remote_user.id)

      if harvest_user.cache == remote_user.as_json
        dir = :sync_diff
      elsif harvest_user.cache == nil
        create = true
        dir = :sync_from
      else
        dir = :sync_diff
      end


      sync_fields = ["active", "first_name","last_name", "email"]
      changed_fields = []

      from = false
      to = false

      if dir == :sync_from

        if harvest_user.user == nil
          harvest_user.user = User.with_deleted.find_or_initialize_by(:email => remote_user.email)
          harvest_user.user.deleted_at = nil
          if !harvest_user.persisted?
            harvest_user.user.password = "psuB17!="
            harvest_user.user.password_confirmation = "psuB17!="
          end
        end
        remote_cache = remote_user.as_json

        sync_fields.each do |field|
          changed_fields << "<--#{field}: #{remote_user[field.gsub("active","is_active")]}"
          harvest_user.user[field] = remote_user[field.gsub("active","is_active")]
          from = true
        end

        harvest_user.cache = remote_cache
        harvest_user.save
        harvest_user.user.save
      end
      if dir == :sync_diff
        hv_up = remote_user.updated_at

        harvest_user.user = User.find_or_initialize_by(email: remote_user.email) if harvest_user.user == nil
        remote_cache = remote_user.as_json

        sync_fields.each do |field|
          if remote_cache['user'][field.gsub("active","is_active")] != harvest_user.cache['user'][field.gsub("active","is_active")]
            changed_fields << "<--#{field}"
            harvest_user.user[field] = remote_user[field.gsub("active","is_active")]
            from = true
            harvest_user.user.save
          end
        end

        harvest_user.cache = remote_cache
        harvest_user.save

        if !from && changed_fields.count == 0
          dir = :sync_to
        end
      end
      if dir == :sync_to


        sync_fields.each do |field|
          if remote_cache['user'][field.gsub("active","is_active")] != harvest_user.user[field]
            changed_fields << "-->#{field}: #{remote_cache['user'][field.gsub("active","is_active")]}/#{harvest_user.user[field]}"

            if field == "active"
              log << "UPDATE #{remote_user.as_json}"
              if harvest_user.user[field]
                #remote_user = hv.harvest.users.activate(remote_user)
              else
                begin
                  #remote_user = hv.harvest.users.deactivate(remote_user)
                rescue Harvest::BadRequest => exception
                  if exception.inspect.include? "Active Cannot archive an inactive user unless it has active projects"

                    #harvest_user.user.visible = false
                    #harvest_user.sync_errors << "Active Cannot archive an inactive user unless it has active projects"
                    harvest_user.user.active = true
                    harvest_user.user.save

                  else
                    throw exception
                  end
                end

              end
              log << "UPDATE #{remote_user.as_json}"
            end

            remote_user.first_name = harvest_user.user[field] if field == "first_name"
            remote_user.last_name = harvest_user.user[field] if field == "last_name"
            remote_user.email = harvest_user.user[field] if field == "email"
            to = true
          end
        end

        if to


          tr = 0
          saved = false
          until saved
            begin
              #remote_cache = hv.harvest.users.update(remote_user).as_json
              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                last_name = harvest_user.user.last_name
                last_name = last_name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                harvest_user.user.last_name = last_name
                harvest_user.user.save
                remote_user.last_name = last_name
              else
                throw exception
              end
            end
          end


          harvest_user.cache = remote_cache
          harvest_user.save
        end

      end
      if !from || !to
        changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
      end
      if(to || from)
        log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_user.user.first_name} #{harvest_user.user.last_name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
      end
    end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end



  def self.find_local_user_by_harvest_id(harvest_id)
    begin
      return HarvestUser.find_by_harvest_id(harvest_id).user
    rescue
      return nil
    end
  end

end
