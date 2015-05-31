class ProjectsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  # GET /projects
  # GET /projects.json
  def index

    #if(params[:active])
      @projects = Project.includes(:project_participants).where(:active => true).load
    #else
    #  @projects = Project.all
    #end

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @projects.as_json(:include => [:client, :project_participants => { :include => [:user] } ] ) }
      format.json { render json: @projects }
    end
  end


  def reserve
    activity = ActivityLog.create({
      dismiss_at: Time.now + 10.minutes,
      user: current_user,
      activity: "project.reserve_code",
      message: "#{current_user} Reserved New Project Code",
      data: Project.next_code })

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @projects.as_json(:include => [:client, :project_participants => { :include => [:user] } ] ) }
      format.json { render json: {code: activity.data} }
    end
  end
  def release
    ActivityLog.where(activity: "project.reserve_code", data: params[:code]).each do |activity|
      activity.dismiss_at = Time.now - 5.minutes
      activity.save
    end

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @projects.as_json(:include => [:client, :project_participants => { :include => [:user] } ] ) }
      format.json { render json: {} }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @projects }
      #format.json { render json: @project.as_json(:include => [:client, :project_participants] ) }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new(params[:project])

    activity = ActivityLog.create({
      dismiss_at: Time.now + 10.minutes,
      user: current_user,
      activity: "project.reserve_code",
      message: "#{current_user} Reserved New Project Code",
      data: Project.next_code })

    @project.code = activity.data

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])

    respond_to do |format|
      if @project.client && @project.save

        pm = ProjectParticipant.with_deleted.find_or_initialize_by(project_id: @project.id, user_id: current_user.id)
        pm.is_manager = true
        pm.restore! if pm.destroyed?
        pm.save

        format.html { redirect_to "/", notice: 'Project was successfully created.' }
        format.json { render json: @project.as_json(:include => [:client, :project_participants ]), status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render json: @project.as_json(:include => [:client, :project_participants ] ) }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    @project.active = false
    @project.save

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end
end
