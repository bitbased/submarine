class ActivityWrapper

  def initialize(tracked_columns = [])
    @tracked_columns = tracked_columns
  end

  def before_save(record)

  end

  def after_save(record)

    chg = {}
    record.changed.each do |r|
      chg[r] = record.send("#{r}_change") if @tracked_columns.include?(r.to_s)
    end

    if chg.count > 0

      current_user = User.current_user
      if !Thread.current[:activity_name].nil? && Thread.current[:activity_name] != ""
        current_user = nil
      end

      activity = ActivityLog.where("change_time > ?", 1.minute.ago).where(:activity => record.id_changed? ? "model.create" : "model.update").where(:user_id => (current_user.id rescue nil)).where(:resource_type => record.class.name).where(:resource_id => record.id).last

      activity = ActivityLog.new if activity.nil?
      activity.message = "#{record.id_changed? ? "Created" : "Updated"} #{record.class.name.titleize} [#{record}]"

      activity.data = {} if activity.data.nil?

      chg.each do |k,v|
        if activity.data[k].nil?
          activity.data[k] = v
        else
          activity.data[k] << v[1]
        end
      end

      activity.data.reject! {|key,value| value[0] == value[1] }

      activity.parent_id = Thread.current[:activity_id] rescue activity.parent_id

      activity.user = current_user

      activity.change_time = Time.now


      activity.activity = record.id_changed? ? "model.create" : "model.update"
      activity.resource_type = record.class.name
      activity.resource_name = "#{record}"
      activity.dismissed_by = nil
      activity.resource_id = record.id
      activity.message = "#{record.id_changed? ? "Created" : "Updated"} #{record.class.name.titleize} \"#{record}\""


      activity.message = "#{current_user} #{record.id_changed? ? "Created" : "Updated"} #{record.class.name.titleize} \"#{record}\"" if current_user
      if current_user == nil
        activity.dismiss_at = Time.now + 5.minutes
      end
      activity.save

      #activity.save if ActivityLog.last.nil? || ActivityLog.last.message != activity.message
    end

  end

  alias_method :after_find, :after_save

  private
    def encrypt(value)
      # Secrecy is committed
    end

    def decrypt(value)
      # Secrecy is unveiled
    end
end