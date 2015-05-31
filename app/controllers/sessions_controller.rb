class SessionsController < ApplicationController

  layout 'landing', :only => [:new]

  def new
    @auth = cookies[:auth_token]
    @auth ||= "NONE"
    @auth = "EMPTY" if @auth == ""
    if current_user
      redirect_to projects_dashboard_index_url
    end
  end

  def create
    auth = User.authenticate(params[:email],params[:password])
    logger.debug "Email: #{params[:email]}"

    @token = cookies[:auth_token]
    #@token = HarvestHook.generate_token(auth)
    @token ||= "NONE"
    @token = "EMPTY" if @token.empty?

    if !auth.nil?

      if params[:remember_me]
        cookies.permanent[:auth_token] = User.generate_token(auth)
      else
        cookies[:auth_token] = User.generate_token(auth)
      end

      @token = current_user
      if !current_user.nil?
        if session[:after_sign_in_path]
          redirect_to login_url, notice: "Logged in."
        else
          redirect_to login_url, notice: "Logged in."
        end
      else
        flash.now.alert = "Email or password is invalid."
        render "new"
      end
    else
      flash.now.alert = "Email or password is invalid. #{auth.inspect}"
      render "new"
    end
  end

  def destroy
    cookies.delete(:auth_token)
    redirect_to login_url, notice: "Logged out."
  end

end