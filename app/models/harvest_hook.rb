require 'harvested.rb'
class HarvestHook

  def harvest
    $harvest ||= {}
    hsh = SubmarineAccount.current_account.id.to_s + "#" + SubmarineAccount.current_account.harvest_subdomain + ":" + SubmarineAccount.current_account.harvest_email
    $harvest[hsh] ||= Harvest.hardy_client(subdomain: SubmarineAccount.current_account.harvest_subdomain, username: SubmarineAccount.current_account.harvest_email, password: SubmarineAccount.current_account.harvest_password)
    return $harvest[hsh]
  end

  def self.authenticate(domain, email, pass)
    begin
      client = Harvest.client(subdomain: domain, username: email, password: pass)
      client.users.find(email)
      return client
    rescue Exception => e
      return nil
    end
  end

  def get_contacts
    harvest.contacts.all #.map { |client| {"id" => client.id, "name" => client.name, "details" => client.details} }
  end

  def get_time_entries(from_date = 7.days.ago, to_date = 1.month.from_now)
    entries = []
    threads = []
    harvest.users.all.each do |user|
      #threads << Thread.new {
        entries += harvest.reports.time_by_user(user.id, from_date, to_date)
      #}
    end
    threads.each { |thr| thr.join }
    return entries
  end

  def get_expense_entries(from_date = 7.days.ago, to_date = 1.month.from_now)
    entries = []
    threads = []
    harvest.users.all.each do |user|
      #threads << Thread.new {
        entries += harvest.reports.expenses_by_user(user.id, from_date, to_date)
      #}
    end
    threads.each { |thr| thr.join }
    return entries
  end

  def get_clients
    harvest.clients.all #.map { |client| {"id" => client.id, "name" => client.name, "details" => client.details} }
  end

  def get_task_categories
    harvest.tasks.all #.map { |client| {"id" => client.id, "name" => client.name, "details" => client.details} }
  end

  def get_expense_categories
    harvest.expense_categories.all #.map { |client| {"id" => client.id, "name" => client.name, "details" => client.details} }
  end

  def get_invoice_categories
    harvest.invoice_categories.all #.map { |client| {"id" => client.id, "name" => client.name, "details" => client.details} }
  end

  def get_projects
    harvest.projects.all #.map { |project| {"id" => project.id, "name" => project.name, "code" => project.code} }
  end

  def get_users
    harvest.users.all #.map { |project| {"id" => project.id, "name" => project.name, "code" => project.code} }
  end

  def get_user_assignments(project_id = nil)
    return harvest.user_assignments.all(project_id) if project_id
    #ua = []
    #get_projects.each do |project|
    #  ua += harvest.user_assignments.all(project.id)
    #end
    #ua
  end

  def get_task_assignments(project_id = nil)
    return harvest.task_assignments.all(project_id) if project_id
    #ua = []
    #get_projects.each do |project|
    #  ua += harvest.task_assignments.all(project.id)
    #end
    #ua
  end

end