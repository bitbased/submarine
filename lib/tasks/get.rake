namespace :get do

  desc "reset"
  task :reset => :environment do |t, args|
    subdomain = args[:subdomain] || SubmarineAccount.first.subdomain
    account_id = SubmarineAccount.where(:subdomain => subdomain).first.id

    ca = SubmarineAccount.find_by_id(account_id)
    SubmarineAccount.current_account = ca if ca

    ActivityLog.delete_all
    HarvestClient.delete_all
    Client.delete_all
    HarvestContact.delete_all
    Contact.delete_all
    HarvestProject.delete_all
    Project.delete_all
    HarvestTaskCategory.delete_all
    TaskCategory.delete_all
    HarvestUserAssignment.delete_all
    ProjectParticipant.delete_all
    Role.delete_all
    Task.delete_all
    HarvestTimeEntry.delete_all
    TimeEntry.delete_all
    HarvestExpenseCategory.delete_all
    ExpenseCategory.delete_all
    HarvestExpenseEntry.delete_all
    HarvestTaskAssignment.delete_all
    ProjectTaskCategoryAssignment.delete_all
    HarvestUserAssignment.delete_all
    ProjectUserAssignment.delete_all
    ExpenseEntry.delete_all
    HarvestUser.delete_all
    User.delete_all
    UserRole.delete_all
    Permalink.delete_all
  end

  desc "get all harvest data"
  task :harvest, [:subdomain] => :environment do |t, args|
    subdomain = args[:subdomain] || SubmarineAccount.first.subdomain
    sync_get(sync: "+all", account_id: SubmarineAccount.where(:subdomain => subdomain).first.id)
  end

  desc "get harvest time"
  task :time, [:subdomain, :days_ago, :days] => :environment do |t, args|
    subdomain = args[:subdomain] || SubmarineAccount.first.subdomain
    days_ago = args[:days_ago] ? args[:days_ago].to_i : 7
    days = args[:days] ? args[:days].to_i : 14
    sync_get(date_from: days_ago.days.ago, date_to: (days_ago - days).days.ago, sync: "+time", account_id: SubmarineAccount.where(:subdomain => subdomain).first.id)
  end

  desc "get all external services"
  task :all, [:subdomain] => [:harvest]


  def sync_get(data = {})

    old_logger = ActiveRecord::Base.logger
    #ActiveRecord::Base.logger = nil

    ca = SubmarineAccount.find_by_id(data[:account_id])

    if ca
      SubmarineAccount.current_account = ca
    end

    log = []

    activity = ActivityLog.new(:activity => "syncronize", :message => "Syncronizing ...")
    activity.running = true
    activity.change_time = DateTime.now
    activity.save

    Thread.current[:activity_name] = :syncronize
    Thread.current[:auto_dismiss] = 5.minutes
    Thread.current[:activity_id] = activity.id

    sync_mode = :only_from

    begin

      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save


      log += HarvestUser.syncronize(sync_mode) if ["all", "+all", "users"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save

      log += HarvestClient.syncronize(sync_mode) if ["all", "+all", "clients"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save


      log += HarvestContact.syncronize(sync_mode) if ["all", "+all", "contacts", "clients"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save

      log += HarvestProject.syncronize(sync_mode) if ["all", "+all", "projects", "clients"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save


      log += HarvestTaskCategory.syncronize(sync_mode) if ["all", "+all", "tasks", "+time"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save

      log += HarvestExpenseCategory.syncronize(sync_mode) if ["all", "+all", "expenses", "+time"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save


      log += HarvestTimeEntry.syncronize(sync_mode, data[:date_from] || 31.days.ago, data[:date_to] || 7.days.from_now) if ["+all", "projects", "time", "+time"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save

      log += HarvestExpenseEntry.syncronize(sync_mode, data[:date_from] || 31.days.ago, data[:date_to] || 7.days.from_now) if ["+all", "expenses", "+time"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save


      log += HarvestInvoiceCategory.syncronize(sync_mode) if ["all", "+all", "expenses"].include?(data[:sync])
      activity.message = "Syncronizing ... \n" + log.join("\n")
      activity.save

      #log += HarvestUserAssignment.syncronize(sync_mode) if ["+all", "projects", "time"].include?(data[:sync])
      #activity.message = "Syncronizing ... \n" + log.join("\n")
      #activity.save

      activity.message = "Syncronizing ... \n" + log.join("\n")
    rescue Exception => e
      activity.message += "\n\n" + e.message + "\n" + e.backtrace.join("\n")
    end


    activity.running = false
    activity.dismiss_at = Time.now + 15.minutes
    activity.change_time = DateTime.now
    activity.save

    puts activity.message

    ActiveRecord::Base.logger = old_logger

  end
end