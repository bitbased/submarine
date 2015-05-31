class DashboardController < ApplicationController

  before_filter :require_login
    
  def index

    @projects = Project.where(:active => true)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  def projects

    if params["query"]
      @projects = []
      Project.includes(:project_participants).each do |p|
        @projects << p if "#{p.code} - #{p.client.name if p.client} - #{p.name} - #{p.status.titleize}".downcase.include?(params["query"].downcase)
      end
    else
      @projects = Project.includes(:project_participants).where(:active => true)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  def clients
    @clients = Client.where(:active => true)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @clients }
    end
  end

end
