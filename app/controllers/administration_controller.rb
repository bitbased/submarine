class AdministrationController < ApplicationController

  def index
    #HarvestUser.delay.syncronize
  end

  def external_syncronization

    #old_logger = ActiveRecord::Base.logger
    #ActiveRecord::Base.logger = nil

    params[:sync] = "all" unless params[:sync]

    if(ActivityLog.where(:running => true).count == 0)
      SYNC_QUEUE << { :user_id => current_user.id, :sync => params[:sync], :account_id => SubmarineAccount.current_account_id }
    end
    #log.map { |v| CGI.escapeHTML(v) }
    #ActiveRecord::Base.logger = old_logger

    sleep(1)

    @activity = ActivityLog.where(:running => true).last

  end



  def process_queue
    count = Delayed::Job.all.count

    w = Delayed::Worker.new({exit_on_complete: true, max_run_time: 15.seconds})
    w.start

render text: <<-CODE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
  <title>Submarine Processing</title>
  <meta http-equiv="REFRESH" content="1;url=">
</head>
<body>
  [#{count}] Jobs Processed ...
</body>
</html>
CODE

  end

  def sync_status
    #Delayed::Job
  end

end
