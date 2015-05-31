class ApplicationController < ActionController::Base
  before_filter :require_login
  protect_from_forgery

  before_filter do |c|
    User.current_user = current_user
  end

private

  def current_user
    #@current_user ||= User.find(session[:user_id]) if session[:user_id]
    begin
      @current_user = User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
    rescue
      cookies.delete(:auth_token)
      @current_user = nil
      #redirect_to root_url, notice: "Session Expired."
    end
  end

  def query_params
    q_params = request.params.dup
    q_params.delete("action")
    q_params.delete("controller")
    return q_params
  end

  def require_login
    SubmarineAccount.current_account = nil

    host_uri = request.host_with_port.downcase
    subdomain = host_uri.gsub(/^(?:([^\.]+)\.)?.*/,'\1')

    SubmarineAccount.current_account = SubmarineAccount.find_by_subdomain(subdomain)
    if SubmarineAccount.current_account.nil?
      if params[:controller] != "submarine_accounts"
        redirect_to "/new", notice: "Please Setup Your Domain"
      end
    else
      if current_user.nil? && params[:controller] != "sessions"
        redirect_to login_url, notice: "Please Login"
      end
    end
  end

  helper_method :query_params
  helper_method :current_user
  helper_method :require_login

end
