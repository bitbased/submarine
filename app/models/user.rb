class User < ActiveRecord::Base
  default_scope { where(:submarine_account_id => SubmarineAccount.current_account_id) }

  cattr_accessor :current_user

  acts_as_paranoid
  has_secure_password

  has_many :harvest_users, :foreign_key => 'user_id'

  belongs_to :contact
  attr_accessible :active, :archived_on, :audit_log, :change_time, :data, :deleted_at, :email, :history, :locked_on, :first_name, :last_name, :notes, :password_digest, :password, :permalog, :priority, :state, :sync, :sync_time, :visible, :password_confirmation

  def harvest_id
    harvest_users.first.harvest_id rescue nil
  end

  def serializable_hash(options={})
    options[:only] = [:first_name, :last_name, :id, :email, :active]
    options[:methods] = [:is_current]
    super(options)
  end

  def is_current
    self == User.current_user
  end

  def to_s
    first_name + " " + last_name
  end

  def time_zone
    "America/Chicago"
  end

  def self.generate_token(user)
    digest = Digest::MD5.hexdigest("*5ecr3t$5ub!s@uce*" + user.id.to_s)
  end

  def self.find_by_auth_token(token)
    User.all.each do |u|
      return u if generate_token(u) == token
    end
    return nil
  end

  def self.authenticate(email, pass)

    #auth = super(email, pass)
    #return auth if auth != nil

    user = User.find_by_email(email)
    #user.harvest_user.domain = 'submarine'

    if user == nil
      HarvestUser.syncronize()
      user = User.find_by_email(email)
    end

    if user
      auth = user.authenticate(pass)
      if auth
        return user
      end
    end

    begin
      temp = HarvestHook.authenticate(SubmarineAccount.current_account.harvest_subdomain, email, pass)
      found = false
      temp.users.all.each do |u|
        if u.email.downcase == email.downcase
          found = true
        end
      end

      if found
        if user == nil
          HarvestUser.syncronize()
          user = User.find_by_email(email)
        end
        user.password = pass
        user.password_confirmation = pass
        user.save
        return user
      end

    rescue
    end

    return nil
  end

end
