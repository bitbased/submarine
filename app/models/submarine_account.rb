class SubmarineAccount < ActiveRecord::Base

  cattr_accessor :current_account

  acts_as_paranoid

  attr_accessible :user_id, :aws_access_key_id, :aws_secret_access_key, :aws_s3_bucket, :domains, :subdomain, :email, :config, :harvest_subdomain, :harvest_email, :harvest_password, :name, :logo_url, :small_logo_url, :config, :running, :progress, :user, :parent_id, :activity, :activity_time, :dismissed_by, :data, :deleted_at, :description, :history, :message, :notes, :resource_data, :resource_id, :resource_name, :resource_state, :resource_type, :show_to, :starred_by, :viewed_by, :visible, :dismiss_at

  serialize :config, JSON


  def aws_s3_bucket=(val)
    self["config"] ||= {}
    self["config"]["aws"] ||= {}
    self["config"]["aws"]["s3_bucket"] = val
  end
  def aws_s3_bucket
    return self["config"]["aws"]["s3_bucket"] rescue nil
  end

  def aws_access_key_id=(val)
    self["config"] ||= {}
    self["config"]["aws"] ||= {}
    self["config"]["aws"]["access_key_id"] = val
  end
  def aws_access_key_id
    return self["config"]["aws"]["access_key_id"] rescue nil
  end

  def aws_secret_access_key=(val)
    self["config"] ||= {}
    self["config"]["aws"] ||= {}
    self["config"]["aws"]["secret_access_key"] = val
  end
  def aws_secret_access_key
    return self["config"]["aws"]["secret_access_key"] rescue nil
  end



  def harvest_subdomain=(val)
    self["config"] ||= {}
    self["config"]["harvest"] ||= {}
    self["config"]["harvest"]["subdomain"] = val
  end
  def harvest_subdomain
    return self["config"]["harvest"]["subdomain"] rescue nil
  end

  def harvest_email=(val)
    self["config"] ||= {}
    self["config"]["harvest"] ||= {}
    self['config']["harvest"]["email"] = val rescue nil
  end
  def harvest_email
    return self['config']["harvest"]["email"] rescue nil
  end

  def harvest_password=(val)
    self["config"] ||= {}
    self["config"]["harvest"] ||= {}
    self['config']["harvest"]["password"] = val rescue nil
  end
  def harvest_password
    return self['config']["harvest"]["password"] rescue nil
  end



  def self.current_account_id
    current_account rescue nil
  end
end
