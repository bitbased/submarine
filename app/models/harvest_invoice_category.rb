class HarvestInvoiceCategory < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }
  acts_as_paranoid
  
  belongs_to :invoice_category
  attr_accessible :active, :archived_on, :audit_log, :cache, :change_time, :data, :deleted_at, :harvest_id, :harvest_project_id, :harvest_user_id, :history, :locked_on, :permalog, :priority, :state, :sync, :sync_time, :visible, :invoice_category_id, :unit_name, :unit_price

  serialize :cache, JSON

  serialize :data, JSON
  serialize :audit_log, JSON
  serialize :permalog, JSON
  serialize :history, JSON
  serialize :sync, JSON

  def self.syncronize(mode = :only_from)
    log = ["InvoiceCategories"]
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

      invoice_categories_cache = []
      ### FIND [NEW] LOCAL CLIENTS ###
      InvoiceCategory.all.each do |invoice_category|
        if invoice_category.harvest_invoice_categories.length == 0
          harvest_invoice_category = HarvestInvoiceCategory.new


          tr = 0
          saved = false
          until saved
            begin
              remote_invoice_category = Harvest::InvoiceCategory.new(:name => invoice_category.name, :deactivated => !invoice_category.active)
              #remote_invoice_category = hv.harvest.invoices.create(remote_invoice_category)

              log << "[NEW+] #{invoice_category.name}"
              
              harvest_invoice_category.harvest_id = remote_invoice_category.id
              harvest_invoice_category.cache = remote_invoice_category.as_json
              harvest_invoice_category = invoice_category.harvest_invoice_categories
              harvest_invoice_category.save

              saved = true
            rescue Harvest::BadRequest => exception
              if exception.inspect.include? "Name has already been taken"
                tr += 1
                invoice_category.name = invoice_category.name.gsub(/~[0-9]+$/,"") + "~#{tr}"
              else
                throw exception
              end
            end
          end


        end
      end

      InvoiceCategory.all.each do |invoice_category|
        invoice_categories_cache += invoice_category.harvest_invoice_categories
      end

      ### RETRIEVE REMOTE CLIENTS ###
      hv_invoice_categories = hv.get_invoice_categories

      ### FIND [DELETED] LOCAL CLIENTS ###
      deleted_cache = []
      InvoiceCategory.only_deleted.each do |invoice_category|
        deleted_cache += invoice_category.harvest_invoice_categories
      end
      deleted_cache.map! { |v| v.harvest_id }

      #log << deleted_cache.inspect

      hv_invoice_categories.each do |dd|
        invoice_categories_cache.reject! { |c| c.harvest_id == dd.id } # <HELPER> FIND [DELETED] REMOTE CLIENTS
        if deleted_cache.include?(dd.id)
          log << "[DELETED] #{dd.name}"
          #hv.harvest.invoices.delete(dd)
        end
      end

      ### FIND [DELETED] REMOTE CLIENTS ###
      invoice_categories_cache.each do |c|
        c.destroy! # no longer keep a reference since we know harvest doesn't
        if c.invoice_category
          log << "[DELETED] #{c.invoice_category.name}"
          c.invoice_category.destroy
        end
      end

      hv_invoice_categories = hv.get_invoice_categories

      ### FIND [NEW] REMOTE CLIENTS ###
      ### SYNC [CHANGED] CLIENTS ###
      hv_invoice_categories.each do |remote_invoice_category|
        harvest_invoice_category = HarvestInvoiceCategory.with_deleted.find_or_initialize_by(harvest_id: remote_invoice_category.id)
        
        if harvest_invoice_category.cache == remote_invoice_category.as_json
          dir = :sync_diff
        elsif harvest_invoice_category.cache == nil
          create = true
          dir = :sync_from
        else
          dir = :sync_diff
        end

        sync_fields = ["name", "use_as_expense", "use_as_service"]
        changed_fields = []

        from = false
        to = false

        if dir == :sync_from
          harvest_invoice_category.invoice_category = InvoiceCategory.find_or_initialize_by(name: remote_invoice_category.name) if harvest_invoice_category.invoice_category == nil
          remote_cache = remote_invoice_category.as_json

          sync_fields.each do |field|
            changed_fields << "<--#{field}"
            if field == "active"
              harvest_invoice_category.invoice_category[field] = !remote_invoice_category["deactivated"]
            else
              harvest_invoice_category.invoice_category[field] = remote_invoice_category[field]
            end
            from = true
          end
          
          harvest_invoice_category.cache = remote_cache
          harvest_invoice_category.save
        end
        if dir == :sync_diff
          hv_up = remote_invoice_category.updated_at

          harvest_invoice_category.invoice_category = InvoiceCategory.find_or_initialize_by(name: remote_invoice_category.name) if harvest_invoice_category.invoice_category == nil
          remote_cache = remote_invoice_category.as_json

          sync_fields.each do |field|

            if field == "active"
              if remote_cache['category']["deactivated"] != harvest_invoice_category.cache['category']["deactivated"]
                changed_fields << "<--#{field}"
                harvest_invoice_category.invoice_category[field] = !remote_invoice_category["deactivated"]
                from = true
                harvest_invoice_category.invoice_category.save
              end
            elsif remote_cache['category'][field] != harvest_invoice_category.cache['category'][field]
              changed_fields << "<--#{field}"
              harvest_invoice_category.invoice_category[field] = remote_invoice_category[field]
              from = true
              harvest_invoice_category.invoice_category.save
            end
          end
          harvest_invoice_category.cache = remote_cache
          harvest_invoice_category.save

          if !from && changed_fields.count == 0
            dir = :sync_to
          end
        end
        if dir == :sync_to

          
          sync_fields.each do |field|


            if field == "active"

              if remote_cache['category']["deactivated"] != !harvest_invoice_category.invoice_category[field]
                changed_fields << "-->#{field}"

                log << "UPDATE #{remote_invoice_category.as_json}"
                if harvest_invoice_category.invoice_category[field]
                  #remote_invoice_category = hv.harvest.invoice_categories.activate(remote_invoice_category)
                else
                  begin
                    #remote_invoice_category = hv.harvest.invoice_categories.deactivate(remote_invoice_category)
                  rescue Harvest::BadRequest => exception
                    if exception.inspect.include? "Active Cannot archive an inactive invoice_category unless it has active projects"
                      
                      #harvest_invoice_category.invoice_category.visible = false
                      #harvest_invoice_category.sync_errors << "Active Cannot archive an inactive invoice_category unless it has active projects"
                      harvest_invoice_category.invoice_category.active = true
                      harvest_invoice_category.invoice_category.save

                    else
                      throw exception
                    end
                  end
                  
                end
                log << "UPDATE #{remote_invoice_category.as_json}"
                to = true
              end

            elsif remote_cache['category'][field] != harvest_invoice_category.invoice_category[field]
              changed_fields << "-->#{field}"

              remote_invoice_category.name = harvest_invoice_category.invoice_category[field] if field == "name"
              remote_invoice_category.use_as_expense = harvest_invoice_category.invoice_category[field] if field == "use_as_expense"
              remote_invoice_category.use_as_service = harvest_invoice_category.invoice_category[field] if field == "use_as_service"
              to = true
            end
          end

          if to


            tr = 0
            saved = false
            until saved
              begin
                #remote_cache = hv.harvest.invoice_categories.update(remote_invoice_category).as_json
                saved = true
              rescue Harvest::BadRequest => exception
                if exception.inspect.include? "Name has already been taken"
                  tr += 1
                  name = harvest_invoice_category.invoice_category.name
                  name = name.gsub(/~[0-9]+$/,"") + "~#{tr}"
                  harvest_invoice_category.invoice_category.name = name
                  harvest_invoice_category.invoice_category.save
                  remote_invoice_category.name = name
                else
                  throw exception
                end
              end
            end


            harvest_invoice_category.cache = remote_cache
            harvest_invoice_category.save
          end

        end
        if !from || !to
          changed_fields.map! { |f| f.gsub(/^[<-]-[-\>]/,"")}
        end
        if(to || from)
          log << "#{ (from && to ? "<->" : (from ? "<--" : (to ? "-->" : "---" ) )).gsub("<", create ? "+" : "<").gsub(">", create ? "+" : ">") } #{harvest_invoice_category.invoice_category.name}#{changed_fields.count >0 ? " " + changed_fields.inspect : ""}"
        end
      end

    rescue Exception => e
      log << e.message + "\n" + e.backtrace.join("\n")
    end
    return log
  end

  def self.find_local_invoice_category_by_harvest_id(harvest_id)
    begin
      return HarvestInvoiceCategory.find_by_harvest_id(harvest_id).invoice_category
    rescue
      return nil
    end
  end

end
